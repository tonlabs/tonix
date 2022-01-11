pragma ton-solidity >= 0.51.0;

import "Utility.sol";
import "../lib/libuadm.sol";

contract chfn is Utility, libuadm {

    function ustat(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out) {
//    function exec(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out) {
        (, string[] args, uint flags) = input.unpack();
        (out, ) = _chfn(flags, args, session, inodes, data);
    }

    function _chfn(uint flags, string[] args, Session session, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string out, Err[] errors) {
        bool print_system = (flags & _s) > 0 || (flags & _u) == 0;
        bool print_user = (flags & _u) > 0 || (flags & _s) == 0;
        string field_separator;
        if ((flags & _c) > 0)
            field_separator = ":";
        field_separator = _if(field_separator, (flags & _n) > 0, "\n");
        field_separator = _if(field_separator, (flags & _r) > 0, " ");
        field_separator = _if(field_separator, (flags & _z) > 0, "\x00");
        if (field_separator.byteLength() > 1)
            return ("Mutually exclusive options\n", [Err(0, mutually_exclusive_options, "")]);
        bool formatted_table = field_separator.empty();
        bool print_all = (print_system || print_user) && args.empty();

        if (formatted_table)
            field_separator = " ";

        string[][] table;
        if (formatted_table)
            table = [["UID", "USER", "GID", "GROUP"]];
        Column[] columns_format = print_all ? [
                Column(print_all, 5, ALIGN_LEFT),
                Column(print_all, 10, ALIGN_LEFT),
                Column(print_all, 5, ALIGN_LEFT),
                Column(print_all, 10, ALIGN_LEFT)] :
               [Column(!print_all, 15, ALIGN_LEFT),
                Column(!print_all, 20, ALIGN_LEFT)];
        mapping (uint16 => UserInfo) users = _get_login_info(inodes, data);

        if (args.empty() && session.uid < GUEST_USER) {
            for ((uint16 uid, UserInfo user_info): users) {
                (uint16 gid, string s_owner, string s_group) = user_info.unpack();
                    table.push([format("{}", uid), s_owner, format("{}", gid), s_group]);
            }
        } else {
            string user_name = args[0];
            for ((uint16 uid, UserInfo user_info): users)
                if (user_info.user_name == user_name) {
                    (uint16 gid, , string s_group) = user_info.unpack();
                    string home_dir = "/home/" + user_name;
                    table = [
                        ["Username:", user_name],
                        ["UID:", format("{}", uid)],
                        ["Home directory:", home_dir],
                        ["Primary group:", s_group],
                        ["GID:", format("{}", gid)]];
                    break;
                }
        }
        out = _format_table_ext(columns_format, table, field_separator, "\n");
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("chfn", "change real user name and information", "[options] [LOGIN]",
            "Changes user fullname for a user account.",
            "f", 1, 2, [
            "change the user's full name"]);
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