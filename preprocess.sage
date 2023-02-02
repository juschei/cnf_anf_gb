#from sage.rings.polynomial.pbori import *
import networkx as nx
from itertools import compress
#import matplotlib.pyplot as plt
import msgspec

def variables(clauses):
    variables = set()
    for c in clauses:
        for L in c:
            variables = variables | {abs(L)}
    return variables


def count_variables(clauses):
    return len(variables(clauses))


def print_conversion(clauses, functions):
    print("Standard Conversion")

    for c, f in zip(clauses, functions):
        c = str(c)
        f = str(f)
        print(c.ljust(15, " "), " <-> ", f)


def standard_conversion(ring, clauses):
    functions = []
    variables = B.gens()

    for c in clauses:
        f = B(1)
        for L in c:
            if L > 0:
                f *= (variables[L] + 1)
            elif L < 0:
                f *= variables[-L]

        functions.append(f)

    return functions


# returns the corresponding overlap graph and a list of leftover
# clauses (the ones with less than m literals)
def construct_graph(clauses, m):

    # preprocessing: set up list of sets of variables for each clause

    # computes the variables of a clause
    def vars(c):
        return [abs(L) for L in c]


    # eliminates double occurences, these however should not exist
    # in the first place due to preprocessing because either these
    # come from one of the two cases
    # L or L (which should be simplified to L)
    # L or ~L (which should be simplified to 1, i.e. both literals
    #   should be deleted)
    clause_sets = [set(vars(c)) for c in clauses]
    n_clauses = len(clauses)

    # computes the number of common variables in c1 and c2
    # input as sets
    def common(c1, c2):
        return len(c1 & c2)

    G = nx.Graph()
    T = list()
    # add node for every clause
    for i in range(n_clauses):
        if len(clauses[i]) >= m:
            G.add_node(i, clause=clauses[i])
        else:
            T.append(clauses[i])
    # draw an edge between two nodes if m or more
    # variables are in common
    for i in range(0, n_clauses):
        for j in range(i, n_clauses):
            c1 = clause_sets[i]
            c2 = clause_sets[j]
            if common(c1, c2) >= m:
                G.add_edge(i, j)

    return G, T


def is_maximal_node(G, n_max):
    n_max_neigh = set(G.neighbors(n_max)).union({n_max})
    for n in G:
        n_neigh = set(G.neighbors(n)).union({n})

        if n_max_neigh < n_neigh:
            return False
    return True


def maximals(G):
    maxims = []
    for n_max in G:
        if is_maximal_node(G, n_max):
            maxims.append(True)
        else:
            maxims.append(False)
    return maxims


def colormap(G):
    colors = []
    for n_max in G:
        if is_maximal_node(G, n_max):
            colors.append("pink")
        else:
            colors.append("cyan")
    return colors


def gen_labels(G):
    labels = {}
    for n in G:
        name_part = str(n) + "\n"
        neighs = set(G.neighbors(n)).union({n})
        neighs = list(neighs)
        neighs = sorted(neighs)
        neighs = map(str, neighs)
        neigh_part = "".join(neighs)

        labels[n] = name_part + neigh_part

        labels[n] = str(G.nodes[n]["clause"])
    return labels


# returns as set of frozensets of frozensets
def representatives(G):
    maxims_mask = maximals(G)
    maxims = list(compress(G.nodes, maxims_mask))

    reps = set()
    for n in maxims:
        neighs = list(G.neighbors(n))
        neighs.append(n)
        neighs = [frozenset(G.nodes[n]["clause"]) for n in neighs]
        neighs = frozenset(neighs)
        reps.add(neighs)

    return reps


def plot_graph(G):
    labels = gen_labels(G)
    colors = colormap(G)


    nx.draw(G, with_labels=True, labels=labels, node_color=colors)
    plt.savefig('plotgraph.png', dpi=300, bbox_inches='tight')
    plt.show()


def build_blocks(m, plot=False):
    G, T = construct_graph(clauses, m)
    G.remove_edges_from(nx.selfloop_edges(G))

    if plot:
        plot_graph(G)

    reps_set = representatives(G) # set of frozensets of frozensets

    return G, reps_set, T

if __name__ == "__main__":

    # read cnf
    ex1 = "example1.cnf"
    ex2 = "larger_example.cnf"
    ex2 = "new2.cnf"
    in_data = open('cnfs/' + ex2).read().splitlines()
    clauses = [[int(n) for n in line.split() if n != '0'] for line in in_data if line[0] not in ('c', 'p')]

    nr_vars = count_variables(clauses)
    print(f"Reading CNF with {nr_vars} variables and {len(clauses)} clauses...")

    # create boolean ring and convert cnf to polynomials
    from sage.rings.polynomial.pbori import BooleanPolynomialRing
    B = BooleanPolynomialRing(nr_vars+1, 'x')
    #B = B.clone(ordering=dp)

    #functions = standard_conversion(B, clauses)
    #print_conversion(clauses, functions)
    #print("std conversion functions:")
    #print(functions)

    # gröbner basis
    #ideal = B.ideal(functions)
    #gb = ideal.groebner_basis(ideal)
    #print("with GB")
    #print(gb)

    print("\n--------------\n")

    G, reps_set, T = build_blocks(2, plot=False)

    #print(reps_set)
    #print(T)
    
    print(reps_set)

    # serialze cnfs and write them to files
    # TODO pass nrwars as GPI space arg
    # TODO pass nr representatives (len(reps_set)) as GPI space arg and also filter out one-element sets
    data_path = "/home/juschei/Desktop/cnf_anf_gb/input/"
    for i, rep in enumerate(reps_set):
        data = msgspec.msgpack.encode(rep)
        with open(data_path + str(i).zfill(3), "wb") as f:
            f.write(data)

    # write number of variables to nr_vars file
    with open(data_path + "nr_vars", "w") as f:
        f.write(str(nr_vars))
    #S = []
    #for rep in reps_set:
        #print(rep)
        #ideal = B.ideal(standard_conversion(B, rep))
        #gb = ideal.groebner_basis()
        #S.append(gb)

    #basis = B.ideal(S).interreduced_basis()
    # this seems to convert it back to the polybori ideal
    # sage.rings.polynomial.pbori.pbori.BooleanPolynomialIdeal
    # otherwise, interreduced_basis() gives the sage type
    # sage.rings.polynomial.multi_polynomial_sequence.PolynomialSequence_gf2
    #basis = B.ideal(basis)
    #print(basis)

    
