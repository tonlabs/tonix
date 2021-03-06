pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract groupadd is Utility {

    function uadm(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, Ar[] ars, Err[] errors) {
        (, , string flags, ) = arg.get_env(args);
        out = "";
        (bool force, bool use_group_id, bool is_system_group, , , , , ) = arg.flag_values("fgr", flags);

        string target_group_name = vars.val("_", args);
        uint16 target_group_id;
        string etc_group = fs.get_file_contents_at_path("/etc/group", inodes, data);
        string etc_passwd = fs.get_file_contents_at_path("/etc/passwd", inodes, data);

        (string primary, ) = uadmin.user_groups(target_group_name, etc_group);
        if (!primary.empty())
            errors.push(Err(uadmin.E_NAME_IN_USE, 0, target_group_name));
        if (use_group_id) {
            string group_id_s = arg.opt_arg_value("g", args);
            uint16 n_gid = str.toi(group_id_s);
            if (n_gid == 0)
                errors.push(Err(uadmin.E_BAD_ARG, 0, group_id_s)); // invalid argument to option
            else
                target_group_id = uint16(n_gid);
            (string group_name, , ) = uadmin.getgrgid(target_group_id, etc_group);
            if (!group_name.empty()) {
                if (force)
                    target_group_id = 0;
                else
                    errors.push(Err(uadmin.E_GID_IN_USE, 0, group_id_s));
            }
        }

        (, , uint16 reg_groups_counter, uint16 sys_groups_counter) = uadmin.get_counters(etc_passwd);
        if (target_group_id == 0)
            target_group_id = is_system_group ? sys_groups_counter++ : reg_groups_counter++;

        if (errors.empty()) {
            uint16 etc_dir = fs.resolve_absolute_path("/etc", inodes, data);
            (uint16 group_index, uint8 group_file_type, uint16 group_dir_idx) = fs.lookup_dir_ext(inodes[etc_dir], data[etc_dir], "group");
            string text = uadmin.group_entry_line(target_group_name, target_group_id);
            if (group_file_type == FT_UNKNOWN) {
                uint16 ic = sb.get_inode_count(inodes);
                ars.push(Ar(IO_MKFILE, FT_REG_FILE, ic, etc_dir, "group", text));
                ars.push(Ar(IO_ADD_DIR_ENTRY, FT_DIR, etc_dir, 1, "", dirent.dir_entry_line(ic, "group", FT_REG_FILE)));
            } else
                ars.push(Ar(IO_UPDATE_TEXT_DATA, FT_REG_FILE, group_index, group_dir_idx, "group", etc_group + text));
        }
        ec = errors.empty() ? EXECUTE_SUCCESS : EXECUTE_FAILURE;
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"groupadd",
"[options] group",
"create a new group",
"Creates a new group account using the default values from the system.",
"-f     exit successfully if the group already exists, and cancel -g if the GID is already used\n\
-g      use GID for the new group\n\
-r      create a system group",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
