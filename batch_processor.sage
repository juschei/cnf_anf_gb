from sage.rings.polynomial.pbori import BooleanPolynomialRing
import msgspec
from . import worker

inpath = "/home/juschei/Desktop/cnf_anf_gb/input/"
outpath = "/home/juschei/Desktop/cnf_anf_gb/output/"


if __name__=="__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--startidx", type=int, required=True)
    TOTAL = 47
    args = parser.parse_args()
    startidx = args.startidx
    for nr in range(startidx, TOTAL, startidx):
        with open(inpath + str(nr).zfill(3), "rb") as f:
            raw = f.read()
            nr_vars, clauses = msgspec.msgpack.decode(raw)
            worker.process(nr_vars, clauses, nr)
		