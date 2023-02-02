from sage.rings.polynomial.pbori import BooleanPolynomialRing
import msgspec
import argparse
import gc
from memory_profiler import profile

inpath = "/home/juschei/Desktop/cnf_anf_gb/input/"
outpath = "/home/juschei/Desktop/cnf_anf_gb/output/"

# initialize polynomial ring globally
# CAREFUL: potential memory leak, this is why it cannot be inside each call
#B = None


def standard_conversion(ring, clauses):
    functions = []
    variables = ring.gens()

    for c in clauses:
        f = ring(1)
        for L in c:
            if L > 0:
                f *= (variables[L] + 1)
            elif L < 0:
                f *= variables[-L]

        functions.append(f)

    return functions


@profile
def process(nr_vars, clauses, nr):

    B = BooleanPolynomialRing(nr_vars+1, 'x')
    ideal = B.ideal(standard_conversion(B, clauses))
    gb = ideal.groebner_basis()

    del B
    
    data = dumps(gb)
    with open(outpath + str(nr).zfill(3), "wb") as f:
        f.write(data)
    

if __name__=="__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--startidx", type=int, required=True)
    parser.add_argument("--total", type=int, required=False)
    parser.add_argument("--nrworkers", type=int, required=False)
    TOTAL = 999
    NR_WORKERS = 4
    args = parser.parse_args()
    startidx = args.startidx


    #BooleanPolynomialRing(nr_vars+1, 'x')

    for nr in range(startidx, TOTAL, NR_WORKERS):
        print("working with file", nr, "now")
        with open(inpath + str(nr).zfill(3), "rb") as f:
            raw = f.read()
            nr_vars, clauses = msgspec.msgpack.decode(raw)
            process(nr_vars, clauses, nr)
        gc.collect()
	
    print("Left the loop!")
    from guppy import hpy
    h = hpy()
    print(h)
    print(h.heap())
