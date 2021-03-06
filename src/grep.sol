pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract grep is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        ec = EXECUTE_SUCCESS;
        (uint16 wd, string[] v_args, string flags, ) = arg.get_env(argv);
        string[] params;
        string[] f_args;
        uint n_args = v_args.length;

        for (uint i = 0; i < n_args; i++) {
            string s_arg = v_args[i];
            (, uint8 ft, , ) = fs.resolve_relative_path(s_arg, wd, inodes, data);
            if (ft == FT_UNKNOWN)
                params.push(s_arg);
            else
                f_args.push(s_arg);
        }

        for (string s_arg: f_args) {
            (uint16 index, uint8 ft, , ) = fs.resolve_relative_path(s_arg, ROOT_DIR, inodes, data);
            if (ft != FT_UNKNOWN)
                out.append(_grep(flags, fs.get_file_contents(index, inodes, data), params) + "\n");
            else {
                err.append("Failed to resolve relative path for" + s_arg + "\n");
                ec = EXECUTE_FAILURE;
            }
        }
    }

    function _grep(string flags, string text, string[] params) private pure returns (string out) {
        (string[] lines, uint n_lines) = stdio.split(text, "\n");
        bool invert_match = arg.flag_set("v", flags);
        bool match_lines = arg.flag_set("x", flags);
        uint n_params = params.length;

        string pattern;
        if (n_params > 0)
            pattern = params[0];

        uint p_len = pattern.byteLength();
        for (uint i = 0; i < n_lines; i++) {
            string line = lines[i];
            if (line.empty())
                continue;
            bool found = false;
            if (match_lines)
                found = line == pattern;
            else {
                if (p_len > 0) {
                    uint l_len = line.byteLength();
                    for (uint j = 0; j < l_len - p_len; j++)
                        if (line.substr(j, p_len) == pattern) {
                            found = true;
                            break;
                        }
                }
            }
            if (invert_match)
                found = !found;
            if (found || p_len == 0)
                out.append(line + "\n");
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"grep",
"[OPTION...] PATTERNS [FILE...]",
"print lines that match patterns",
"Searches for PATTERNS in each FILE and prints each line that matches a pattern.",
"-v      invert the sense of matching, to select non-matching lines\n\
-x      select only those matches that exactly match the whole line",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
