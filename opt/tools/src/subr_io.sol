pragma ton-solidity >= 0.62.0;

import "libshellenv.sol";
import "libio.sol";
import "Base.sol";

contract subr_io is Base {

    using libshellenv for shell_env;
    using libio for s_thread;

    function main(shell_env e_in, s_proc p_in, s_sbuf[] b_in) external pure returns (shell_env e, s_proc p, s_sbuf[] b) {
        e = e_in;
        p = p_in;
        b = b_in;
        string[] sq = e.environ[sh.SIGNAL];
        for (string line: sq) {
            (, string name, string value) = vars.split_var_record(line);
            uint16 num = str.toi(name);
            (string[] args, ) = libstring.split(value, ' ');
            e.puts("Syscall " + name + " args: " + value);

            s_sigqueue siq;
	        uint16 code;
	        uint16 original_code;
	        s_sysent callp;
	        uint16[8] scargs;
            s_syscall_args sargs = s_syscall_args(code, original_code, callp, scargs);
            s_thread t = s_thread(p, p.p_pid + 1, siq, 0, 0, 0, p.p_ucred, p.p_ucred, p.p_limit, libproc.syscall_name(num), 0, 0, sargs, td_states.TDS_RUNNING, 0);
//            s_thread t;// = s_thread(p, p.p_pid + 1, 0, 0, p.p_ucred, p.p_ucred, p.p_limit, libfdt.syscall_name(num), 0, td_states.TDS_RUNNING, 0);
            uint8 ec = t.do_syscall(num, args);
            uint32 rv = t.td_retval;
            s_of[] res = t.td_proc.p_fd.fdt_ofiles;

            e.puts("Syscall [io] " + name + " ec: " + str.toa(ec) + " result: " + str.toa(rv));
            e.puts(_print_fdt(res));
            if (ec == 0) {
                p.p_fd.fdt_ofiles = res;
                p.p_fd.fdt_nfiles = uint16(res.length);
            }

        }
    }

    function _print_fdt(s_of[] files) internal pure returns (string out) {
        out.append("COMMAND\tPID\tPPID\tUSER\tFD\tTYPE\tDEVICE\tSIZE/OFF\tNODE\tNAME \n");
        for (s_of f: files) {
            (uint attr, uint16 flags, uint16 file, string path, , ) = f.unpack();
            (uint16 st_dev, uint16 st_ino, uint16 st_mode, /*uint16 st_nlink*/, uint16 st_uid, /*uint16 st_gid*/, , uint32 st_size,
                , , , ) = libstat.st_attrs(attr);
            string sm = (flags & io.SRD) > 0 ? "r" : (flags & io.SWR) > 0 ? "w" : (flags & io.SRW) > 0 ? "rw" : "?";
            uint32 sizoff = st_size;
            out.append(format("{}\t{}\t{}\t{}\t{}{}\t{}\t{},{}\t{}\t{}\t{}\n", "", 0, 0 , str.toa(st_uid), file, sm, libstat.ft_desc(st_mode),
                st_dev >> 8, st_dev & 0xFF, sizoff, st_ino, path));
        }
    }
}