pragma ton-solidity >= 0.51.0;

import "Utility.sol";

contract realpath is Utility {

    function exec(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Err[] errors) {
        (, string[] args, uint flags) = input.unpack();
        (out, errors) = _realpath(flags, args, session.wd, inodes, data);
    }

    function _realpath(uint flags, string[] s_args, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string out, Err[] errors) {
        bool canon_existing = (flags & _e) > 0;
        bool canon_missing = (flags & _m) > 0;
        bool canon_existing_dir = (flags & _m + _e) == 0;
//        bool logical = (flags & _L) > 0;
//        bool physical = (flags & _P) > 0;
        bool expand_symlinks = (flags & _s) == 0;
        bool print_errors = (flags & _q) == 0;
        string line_delimiter = (flags & _z) > 0 ? "\x00" : "\n";

        for (string s_arg: s_args) {
            (string arg_dir, string arg_base) = _dir(s_arg);
            bool is_abs_path = s_arg.substr(0, 1) == "/";
            string path = is_abs_path ? s_arg : _xpath(s_arg, wd, inodes, data);
            uint16 cur_dir = is_abs_path ? _resolve_absolute_path(arg_dir, inodes, data) : wd;

            if ((canon_existing_dir || canon_existing) && expand_symlinks) {
                (uint16 index, uint8 ft) = _lookup_dir(inodes[cur_dir], data[cur_dir], arg_base);
                if (ft == FT_SYMLINK)
                    (path, ft, , ,) = _dereference(EXPAND_SYMLINKS, s_arg, wd, inodes, data).unpack();
                if (!canon_missing && index < INODES) {
                    if (print_errors)
                        errors.push(Err(0, index, s_arg));
                    continue;
                }
            }
            out.append(path + line_delimiter);
        }
    }

    /* Path utilities helpers */
    function _abs_path_walk_up(uint16 dir, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string path) {
        uint16 cur_dir = dir;
        while (cur_dir > ROOT_DIR) {
            Inode inode = inodes[cur_dir];
            path = inode.file_name + "/" + path;
            (DirEntry[] contents, int16 status) = _read_dir(inode, data[cur_dir]);
            if (status > 1)
                cur_dir = contents[1].index;
        }
    }

    function _canonicalize(uint16 mode, string s_arg, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string res, bool valid) {
        uint16 canon_mode = mode & 3;
        (string arg_dir, string arg_base) = _dir(s_arg);
        bool is_abs_path = s_arg.substr(0, 1) == "/";
        valid = true;

        if (canon_mode >= CANON_DIRS) {
            uint16 dir_index = is_abs_path ? _resolve_absolute_path(arg_dir, inodes, data) : wd;
            (, uint8 ft) = _lookup_dir(inodes[dir_index], data[dir_index], arg_base);
            if (ft == FT_UNKNOWN)
                valid = false;
        }

        res = canon_mode == CANON_NONE || (canon_mode == CANON_MISS || canon_mode == CANON_EXISTS) && is_abs_path ?
            s_arg : canon_mode == CANON_DIRS ? _xpath(arg_dir, _resolve_absolute_path(arg_dir, inodes, data), inodes, data) + "/" + arg_base : _xpath(s_arg, wd, inodes, data);
    }

    function _dereference(uint16 mode, string s_arg, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (Arg) {
        bool expand_symlinks = (mode & EXPAND_SYMLINKS) > 0;
        (uint16 ino, uint8 ft, uint16 parent, uint16 dir_index) = _resolve_relative_path(s_arg, wd, inodes, data);
        Inode inode;
        if (ino > 0 && inodes.exists(ino))
            inode = inodes[ino];
        if (expand_symlinks && ft == FT_SYMLINK) {
            (ft, s_arg, ino) = _get_symlink_target(inode, data[ino]).unpack();
        }
        return Arg(s_arg, ft, ino, parent, dir_index);
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("realpath", "print the resolved path", "[OPTION]... FILE...",
            "Print the resolved absolute file name; all but the last component must exist.",
            "emLPqsz", 1, M, [
            "all components of the path must exist",
            "no path components need exist or be a directory",
            "resolve '..' components before symlinks",
            "resolve symlinks as encountered (default)",
            "suppress most error messages",
            "don't expand symlinks",
            "end each output line with NUL, not newline"]);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"",
"OPTION... [FILE]...",
"",
"",
"-a     d",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}