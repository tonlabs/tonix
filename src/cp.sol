pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract cp is Utility {

    function induce(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Ar[] ars, Err[] errors) {
        (uint16 wd, string[] params, string flags, ) = arg.get_env(args);
        Arg[] arg_list;
        for (string s_arg: params) {
            (uint16 index, uint8 ft, uint16 parent, uint16 dir_index) = fs.resolve_relative_path(s_arg, wd, inodes, data);
            arg_list.push(Arg(s_arg, ft, index, parent, dir_index));
        }
        (out, ars, errors) = _cp(params, flags, wd, arg_list, sb.get_inode_count(inodes), inodes);
    }

    function _cp(string[] args, string flags, uint16 wd, Arg[] arg_list, uint16 ic, mapping (uint16 => Inode) inodes) private pure returns (string out, Ar[] ars, Err[] errors) {
        (bool verbose, bool preserve, bool request_backup, bool to_file_flag, bool to_dir_flag, bool newer_only, bool force, bool recurse)
            = arg.flag_values("vnbTtufr", flags);
        bool hardlink = arg.flag_set("l", flags);
        bool symlink = arg.flag_set("s", flags);

        if (hardlink && symlink)
            errors.push(Err(er.hard_or_symlink, 0, ""));

        bool to_dir = to_dir_flag;
        uint nargs = args.length;

        uint last;
        uint first;
        uint target_n;

        if (to_dir_flag) {
            first = 1;
            last = nargs;
            target_n = 0;
        } else {
            first = 0;
            last = nargs - 1;
            target_n = nargs - 1;
        }
        (string t_path, uint8 t_ft, uint16 t_ino, /*uint16 t_parent*/, uint16 t_idx) = arg_list[target_n].unpack();
        bool dest_exists = t_ino >= INODES;

        if (dest_exists && t_ft == FT_DIR)
            to_dir = true;

        bool collision = dest_exists && t_ft == FT_REG_FILE;
        bool overwrite_dest = collision && (!preserve || force);

        if (!errors.empty() || collision && preserve)
            return (out, ars, errors);

        string dirents;
        if (request_backup && overwrite_dest) {
            string t_backup_path = t_path + "~";
            out = str.aif(out, verbose, "(backup:" + str.quote(t_backup_path) + ")");

            ars.push(Ar(IO_WR_COPY, FT_REG_FILE, 0, t_ino, t_backup_path, ""));
            dirents.append(dirent.dir_entry_line(t_ino, t_backup_path, FT_REG_FILE));
            ic++;
        }

        uint8 action_item_type = symlink ? IO_SYMLINK : hardlink ? IO_HARDLINK : IO_WR_COPY;

        for (uint i = first; i < last; i++) {
            (string s_path, uint8 s_ft, uint16 s_ino, , uint16 s_dir_idx) = arg_list[i].unpack();

            if (s_ino < INODES) { errors.push(Err(0, s_ino, s_path)); break; }
            if (verbose) { out.append(str.quote(s_path) + "=>" + str.quote(t_path)); }

            if (s_ft == FT_DIR && action_item_type == IO_HARDLINK)
                errors.push(Err(er.no_hardlink_on_dir, 0, s_path));
            if (s_ft == FT_DIR && action_item_type == IO_WR_COPY && !recurse)
                errors.push(Err(er.omitting_directory, 0, s_path));
            else if (to_file_flag && to_dir && s_ft == FT_REG_FILE)
                errors.push(Err(er.cant_overwrite_dir, 0, str.quote(t_path)));
            else if (collision && newer_only) {
                if (inodes[t_ino].modified_at > inodes[s_ino].modified_at)
                    continue;
            } else {
                (, string file_name) = path.dir(to_dir ? s_path : t_path);

                ars.push(Ar(action_item_type, s_ft, s_ino, s_dir_idx, file_name, ""));
                dirents.append(dirent.dir_entry_line(action_item_type == IO_HARDLINK ? s_ino : ic++, file_name, s_ft));
            }
        }

        if (!dirents.empty())
            ars.push(Ar(IO_ADD_DIR_ENTRY, FT_DIR, to_dir ? t_ino : wd, t_idx, "", dirents));

        if (overwrite_dest && errors.empty())
            ars.push(Ar(IO_UNLINK, t_ft, t_ino, t_idx, t_path, ""));
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"cp",
"[OPTION]... [-T] SOURCE DEST\n\tcp [OPTION]... SOURCE... DIRECTORY\n\tcp [OPTION]... -t DIRECTORY SOURCE...",
"copy files and directories",
"Copy SOURCE to DEST, or multiple SOURCE(s) to DIRECTORY.",
"-a      same as -dR -p\n\
-b      make a backup of each existing destination file\n\
-d      same as -P, preserve links\n\
-f      if an existing destination file cannot be opened, remove it and try again\n\
-H      follow command-line symbolic links in SOURCE\n\
-l      hard link files instead of copying\n\
-L      always follow symbolic links in SOURCE\n\
-n      do not overwrite an existing file\n\
-P      never follow symbolic links in SOURCE\n\
-p      preserve mode, ownership, timestamps\n\
-r      \n\
-R      copy directories recursively\n\
-s      make symbolic links instead of copying\n\
-t      copy all SOURCE arguments into DIRECTORY\n\
-T      treat DEST as a normal file\n\
-u      copy only when the SOURCE file is newer than the destination file or when the destination file is missing\n\
-v      explain what is being done\n\
-x      stay on this file system",
"The backup suffix is '~'. As a special case, cp makes a backup of SOURCE when the force and backup options are given\n\
and SOURCE and DEST are the same name for an existing, regular file.",
"Written by Boris",
"",
"",
"0.01");
    }

}
