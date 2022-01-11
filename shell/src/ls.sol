pragma ton-solidity >= 0.53.0;

import "Utility.sol";
import "../lib/libuadm.sol";

contract ls is Utility, libuadm {

    function exec(string[] e, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        ec = EXECUTE_SUCCESS;
        (string[] params, string flags, ) = _get_args(e[IS_ARGS]);
        for (string arg: params) {
            (uint16 index, uint8 ft, uint16 parent, uint16 dir_index) = _resolve_relative_path(arg, ROOT_DIR, inodes, data);
            if (ft != FT_UNKNOWN)
                out.append(_ls(flags, Arg(arg, ft, index, parent, dir_index), inodes, data) + "\n");
            else
                err.append("Failed to resolve relative path for" + arg + "\n");
        }
    }

    function _ls_sort_rating(string f, Inode inode, string name, uint16 dir_idx) private pure returns (uint rating) {
        bool use_ctime = _flag_set("c", f);
        bool largest_first = _flag_set("S", f);
        bool directory_order = _flag_set("U", f) || _flag_set("f", f);
        bool newest_first = _flag_set("t", f);
        bool reverse_order = _flag_set("r", f);
        uint rating_lo = directory_order ? dir_idx : _alpha_rating(name, 8);
        uint rating_hi;

        if (newest_first)
            rating_hi = use_ctime ? inode.modified_at : inode.last_modified;
        else if (largest_first)
            rating_hi = 0xFFFFFFFF - inode.file_size;
        rating = (rating_hi << 64) + rating_lo;
        if (reverse_order)
            rating = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - rating;
    }

    function _ls_populate_line(string f, Inode inode, uint16 index, string name, uint8 file_type, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string[] l) {
        bool long_format = _flag_set("l", f) || _flag_set("n", f) || _flag_set("g", f) || _flag_set("o", f);
        bool print_index_node = _flag_set("i", f);
        bool no_owner = _flag_set("g", f);
        bool no_group = _flag_set("o", f);
        bool no_group_names = _flag_set("G", f);
        bool numeric = _flag_set("n", f);
        bool human_readable = _flag_set("h", f);
        bool print_allocated_size = _flag_set("s", f);
        bool double_quotes = _flag_set("Q", f) && !_flag_set("N", f);
        bool append_slash_to_dirs = _flag_set("p", f) || _flag_set("F", f);
        bool use_ctime = _flag_set("c", f);

        (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, uint32 modified_at, uint32 last_modified, ) = inode.unpack();
        if (print_index_node)
            l = [format("{}", index)];
        if (print_allocated_size)
            l.push(format("{}", n_blocks));

        if (long_format) {
            l.push(_permissions(mode));
            l.push(format("{}", n_links));
            if (numeric) {
                if (!no_owner)
                    l.push(format("{}", owner_id));
                if (!no_group)
                    l.push(format("{}", group_id));
            } else {
                string s_owner = _get_user_name(owner_id, inodes, data);
                string s_group = _get_group_name(group_id, inodes, data);

                if (!no_owner)
                    l.push(s_owner);
                if (!no_group && !no_group_names)
                    l.push(s_group);
            }

            if (file_type == FT_CHRDEV || file_type == FT_BLKDEV) {
                (string major, string minor) = _get_device_version(device_id);
                l.push(format("{:4},{:4}", major, minor));
            } else
                l.push(_scale(file_size, human_readable ? KILO : 1));

            l.push(_ts(use_ctime ? modified_at : last_modified));
        }
        if (double_quotes)
            name = "\"" + name + "\"";
        if (append_slash_to_dirs && file_type == FT_DIR)
            name.append("/");
        l.push(name);
    }

    function _ls(string f, Arg arg, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string out) {
        (string s, uint8 ft, uint16 index, , ) = arg.unpack();
        Inode dir_inode = inodes[index];
        string[][] table;
        Arg[] sub_args;
        if (ft == FT_REG_FILE || ft == FT_DIR && _flag_set("d", f)) {
            if (!_ls_should_skip(f, s))
                table.push(_ls_populate_line(f, dir_inode, index, s, ft, inodes, data));
        } else if (ft == FT_DIR) {
            string ret;
            (ret, sub_args) = _list_dir(f, arg, dir_inode, inodes, data);
            out.append(ret);
        }

        for (Arg sub_arg: sub_args)
            out.append("\n" + sub_arg.path + ":\n" + _ls(f, sub_arg, inodes, data));
    }

    function _list_dir(string f, Arg arg, Inode inode, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string out, Arg[] sub_args) {
        (string s, uint8 ft, uint16 index, , ) = arg.unpack();

        bool recurse = _flag_set("R", f);
        bool long_format = _flag_set("l", f) || _flag_set("n", f) || _flag_set("g", f) || _flag_set("o", f);
        bool print_allocated_size = _flag_set("s", f);

        // record separator: newline for long format or -1, comma for -m, tabulation otherwise (should be columns)
        string sp = long_format || _flag_set("1", f) ? "\n" : _flag_set("n", f) ? ", " : "  ";
        string[][] table;

        mapping (uint => uint16) ds;
        bool count_totals = long_format || print_allocated_size;
        uint16 total_blocks;

        if (ft == FT_REG_FILE || ft == FT_DIR && _flag_set("d", f)) {
            if (!_ls_should_skip(f, s))
                table.push(_ls_populate_line(f, inode, index, s, ft, inodes, data));
        } else if (ft == FT_DIR) {
            (DirEntry[] contents, int16 status) = _read_dir_data(data[index]);
            if (status < 0) {
                out.append(format("Error: {} \n", status));
                return (out, sub_args);
            }
            uint len = uint(status);

            for (uint16 j = 0; j < len; j++) {
                (uint8 sub_ft, string sub_name, uint16 sub_index) = contents[j].unpack();
                if (_ls_should_skip(f, sub_name) || sub_ft == FT_UNKNOWN)
                    continue;
                if (recurse && sub_ft == FT_DIR && j > 1)
                    sub_args.push(Arg(s + "/" + sub_name, sub_ft, sub_index, index, j));
                if (count_totals)
                    total_blocks += inodes[sub_index].n_blocks;
                ds[_ls_sort_rating(f, inodes[sub_index], sub_name, j)] = j;
            }

            optional(uint, uint16) p = ds.min();
            while (p.hasValue()) {
                (uint xk, uint16 j) = p.get();
                if (j >= len) {
                    out.append(format("Error: invalid entry {}\n", j));
                    continue;
                }
                (uint8 ftt, string name, uint16 i) = contents[j].unpack();

                table.push(_ls_populate_line(f, inodes[i], i, name, ftt, inodes, data));
                p = ds.next(xk);
            }
        }
        out = _if(out, count_totals, format("total {}\n", total_blocks));
        out.append(_format_table(table, " ", sp, ALIGN_RIGHT));
    }

    /* Decides whether ls should skip this entry with the set of flags */
    function _ls_should_skip(string f, string name) private pure returns (bool) {
        bool print_dot_starters = _flag_set("a", f) || _flag_set("f", f);
        bool skip_dot_dots = _flag_set("A", f);
        bool ignore_blackups = _flag_set("B", f);

        uint len = name.byteLength();
        if (len == 0 || (skip_dot_dots && (name == "." || name == "..")))
            return true;
        if ((name.substr(0, 1) == "." && !print_dot_starters) ||
            (name.substr(len - 1, 1) == "~" && ignore_blackups))
            return true;
        return false;
    }

    function _command_info() internal override pure returns
        (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("ls", "list directory contents", "[OPTION]... [FILE]...",
            "List information about the FILE (the current directory by default).",
            "aABcCdfFgGhHikLlmnNopqQrRsStuUvxX1", 1, M, [
            "do not ignore entries starting with .",
            "do not list implied . and ..",
            "do not list implied entries ending with ~",
            "with -lt: sort by, and show, ctime; with -l: show ctime and sort by name, otherwise: sort by ctime, newest first",
            "list entries by columns",
            "list directories themselves, not their contents",
            "do not sort, enable -aU",
            "append indicator (one of */=>@|) to entries",
            "like -l, but do not list owner",
            "in a long listing, don't print group names",
            "with -l and -s, print sizes like 1K 234M 2G etc.",
            "follow symbolic links listed on the command line",
            "print the index number of each file",
            "default to 1024-byte blocks for disk usage; used only with -s and per directory totals",
            "for a symbolic link, show information for the file the link references rather than for the link itself",
            "use a long listing format",
            "fill width with a comma separated list of entries",
            "like -l, but list numeric user and group IDs",
            "print entry names without quoting",
            "like -l, but do not list group information",
            "append / indicator to directories",
            "print ? instead of nongraphic characters",
            "enclose entry names in double quotes",
            "reverse order while sorting",
            "list subdirectories recursively",
            "print the allocated size of each file, in blocks",
            "sort by file size, largest first",
            "sort by modification time, newest first",
            "with -lt: sort by, and show, access time; with -l: show access time and sort by name; otherwise: sort by access time, newest first",
            "do not sort; list entries in directory order",
            "natural sort of (version) numbers within text",
            "list entries by lines instead of by columns",
            "sort alphabetically by entry extension",
            "list one file per line. Avoid \'\\n\' with -q or -b"]);
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