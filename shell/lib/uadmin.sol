pragma ton-solidity >= 0.55.0;

import "stdio.sol";

library uadmin {

    function user_groups(string user_name, string etc_group) internal returns (string primary, string[] supp) {
        (string[] lines, ) = stdio.split(etc_group, "\n");
        for (string line: lines) {
            (string group_name, , string member_list) = parse_group_entry_line(line);
            if (user_name == group_name)
                primary = group_name;
            if (stdio.strstr(member_list, user_name) > 0)
                supp.push(group_name);
        }
    }

    function parse_group_entry_line(string line) internal returns (string name, uint16 gid, string members) {
        (string[] fields, uint n_fields) = stdio.split(line, ":");
        if (n_fields > 2) {
            name = fields[0];
            gid = stdio.atoi(fields[2]);
            members = n_fields > 3 ? fields[3] : name;
        }
        if (gid == 0 && name != "root")
            gid = 10000;
    }

    function parse_passwd_entry_line(string line) internal returns (string name, uint16 uid, uint16 primary_gid, string home_dir) {
        (string[] fields, uint n_fields) = stdio.split(line, ":");
        if (n_fields > 5) {
            name = fields[0];
            uid = stdio.atoi(fields[2]);
            primary_gid = stdio.atoi(fields[3]);
            home_dir = fields[4];
        }
        if (primary_gid == 0 && name != "root")
            primary_gid = 10000;
        if (uid == 0 && name != "root")
            uid = 10000;
    }

    function group_name_by_id(uint16 gid, string etc_group) internal returns (string) {
        (string[] lines, ) = stdio.split(etc_group, "\n");
        for (string line: lines) {
            (string group_name, uint16 id, ) = parse_group_entry_line(line);
            if (id == gid)
                return group_name;
        }
    }

    function group_entry_by_name(string name, string etc_group) internal returns (string) {
        (string[] lines, ) = stdio.split(etc_group, "\n");
        for (string line: lines) {
            (string group_name, , ) = parse_group_entry_line(line);
            if (name == group_name)
                return line;
        }
    }

    function passwd_entry_by_primary_gid(uint16 gid, string etc_passwd) internal returns (string) {
        (string[] lines, ) = stdio.split(etc_passwd, "\n");
        for (string line: lines) {
            (, , uint16 primary_gid, ) = parse_passwd_entry_line(line);
            if (primary_gid == gid)
                return line;
        }
    }

    function passwd_entry_line(string user_name, uint16 user_id, uint16 group_id, string group_name) internal returns (string) {
        return format("{}:x:{}:{}:{}:/home/{}:\n", user_name, user_id, group_id, group_name, user_name);
    }

    function group_entry_line(string group_name, uint16 group_id) internal returns (string) {
        return format("{}:x:{}:\n", group_name, group_id);
    }

    uint16 constant FAILLOG_ENAB    = 1;
    uint16 constant LOG_UNKFAIL_ENAB = 2;
    uint16 constant LOG_OK_LOGINS   = 3;
    uint16 constant SYSLOG_SU_ENAB  = 4;
    uint16 constant SYSLOG_SG_ENAB  = 5;
    uint16 constant SULOG_FILE      = 6;
    uint16 constant FTMP_FILE       = 7;
    uint16 constant SU_NAME         = 8;
    uint16 constant ENV_SUPATH      = 9;
    uint16 constant ENV_PATH        = 10;
    uint16 constant TTYGROUP        = 11;
    uint16 constant TTYPERM         = 12;
    uint16 constant UID_MIN         = 13; // Min/max values for automatic uid selection in useradd
    uint16 constant UID_MAX         = 14;
    uint16 constant SYS_UID_MIN     = 15;
    uint16 constant SYS_UID_MAX     = 16;
    uint16 constant GID_MIN         = 17; // Min/max values for automatic gid selection in groupadd
    uint16 constant GID_MAX         = 18;
    uint16 constant SYS_GID_MIN     = 19;
    uint16 constant SYS_GID_MAX     = 20;
    uint16 constant CHFN_RESTRICT   = 21;
    uint16 constant DEFAULT_HOME    = 22;
    uint16 constant USERGROUPS_ENAB = 23;
    uint16 constant CONSOLE_GROUPS  = 24;
    uint16 constant CREATE_HOME     = 25;

    uint8 constant E_SUCCESS       = 0; // success
    uint8 constant E_USAGE         = 2; // invalid command syntax
    uint8 constant E_BAD_ARG       = 3; // invalid argument to option
    uint8 constant E_GID_IN_USE    = 4; // specified group doesn't exist <- copy/paste error
    uint8 constant E_NOTFOUND      = 6; // specified group doesn't exist
    uint8 constant E_NAME_IN_USE   = 9; // group name already in use
    uint8 constant E_GRP_UPDATE    = 10; // can't update group file
    uint8 constant E_CLEANUP_SERVICE = 11; // can't setup cleanup service
    uint8 constant E_PAM_USERNAME  = 12; // can't determine your username for use with pam
    uint8 constant E_PAM_ERROR     = 13; // pam returned an error, see syslog facility id groupmod for the PAM error message
}
