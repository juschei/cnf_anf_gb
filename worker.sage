print("HI")
import traceback
print("HI")
try:
	import argparse
	from sage.rings.polynomial.pbori import BooleanPolynomialRing
	import msgspec
except:
	traceback.print_exc()

inpath = "/home/juschei/Desktop/cnf_anf_gb/input/"
outpath = "/home/juschei/Desktop/cnf_anf_gb/output/"


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
    

def process(nr_vars, clauses, nr):
	B = BooleanPolynomialRing(nr_vars+1, 'x')
	ideal = B.ideal(standard_conversion(B, clauses))
	gb = ideal.groebner_basis()
	
	data = dumps(gb)
	with open(outpath + str(nr).zfill(3), "wb") as f:
		f.write(data)
		


if __name__=="__main__":
	parser = argparse.ArgumentParser()
	parser.add_argument("--nr", type=int, required=True)
	args = parser.parse_args()
	nr = args.nr
	with open(inpath + str(nr).zfill(3), "rb") as f:
		raw = f.read()
		nr_vars, clauses = msgspec.msgpack.decode(raw)
		process(nr_vars, clauses, nr)
		