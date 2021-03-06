pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract login is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        err = "";
//        ( , string[] params, string flags, ) = arg.get_env(argv);
        if (!argv.empty() && !inodes.empty() && !data.empty())
            ec = EXECUTE_SUCCESS;
        out = "";

          /*uint n_args = args.length;

        bool force;
        bool use_hostname;
        bool autologin;
        string a_host_name;
        string a_user_name;

        if (autologin) {
            a_host_name = args[0];
            a_user_name = i_user_name;
        } else if (use_hostname) {
            a_host_name = args[0];
            a_user_name = n_args > 1 ? args[1] : i_user_name;
        } else {
            a_host_name = i_host_name;
            a_user_name = args[0];
        }

        if (autologin) {
            session_out = Session(i_pid, i_uid, i_gid, ROOT_DIR, a_user_name, i_group_name, a_host_name, ROOT);
        } else {
            uint16 etc_dir = fs.resolve_absolute_path("/etc", inodes, data);
            (uint16 passwd_index, uint8 passwd_file_type) = fs.lookup_dir(inodes[etc_dir], data[etc_dir], "passwd");
            (uint16 group_index, uint8 group_file_type) = fs.lookup_dir(inodes[etc_dir], data[etc_dir], "group");
            string etc_passwd;
            string etc_group;
            if (passwd_file_type == FT_REG_FILE) {
                etc_passwd = fs.get_file_contents(passwd_index, inodes, data);
            }
            if (group_file_type == FT_REG_FILE)
                etc_group = fs.get_file_contents(group_index, inodes, data);
            uint16 pid = i_pid;
            uint16 uid = i_uid;
            uint16 gid = i_gid;
            uint16 wd = ROOT_DIR;
            string host_name = a_host_name;
            string user_name = a_user_name;
            string group_name = i_group_name;
            string cwd = i_cwd;
//            session_out = Session(pid, uid, gid, wd, user_name, group_name, host_name, cwd);
        }

        /*uint16 uid;
        UserInfo user_info;
        uint u_ord;
        mapping (uint16 => UserInfo) users = _get_login_info(inodes, data);
        for ((uint16 userid, UserInfo ui): users) {
            u_ord++;
            if (i_user_name == ui.user_name) {
                uid = userid;
                user_info = ui;
                break;
            }
        }
        (uint16 gid, string user_name, string group_name) = user_info.unpack();

        uint16 pid = uint16(u_ord);

        string i_cwd = ROOT;
        uint16 wd = fs.resolve_absolute_path(i_cwd, inodes, data);
        string cwd;
        if (wd > INODES)
            cwd = i_cwd;
        else {
            cwd = ROOT;
            wd = ROOT_DIR;
        }
        (string[] lines, ) = stdio.split(fs.get_file_contents_at_path("/etc/hosts", inodes, data), "\n");
        string host_name;
        for (string s: lines) {
            (string[] fields, uint n_fields) = stdio.split(s, "\t");
            if (n_fields > 1 && fields[1] == i_host_name) {
                host_name = i_host_name;
                break;
            }
        }
        session_out = Session(pid, uid, gid, wd, user_name, group_name, host_name, cwd);*/
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"login",
"[-h host] [username] -r host",
"begin session on the system",
"Establish a new session with the system.",
"-f      do not perform authentication, user is preauthenticated\n\
-h      name of the remote host for this login\n\
-r      perform autologin protocol for rlogin",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
