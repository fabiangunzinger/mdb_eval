import concurrent.futures
import os
import multiprocessing as mp


def double(n):
    print("I'm process", os.getpid())
    return n * 2

def main():
    with concurrent.futures.ProcessPoolExecutor() as executor:
        result = executor.map(double, [1, 2, 3, 4, 5])

    print(list(result))


if __name__ == "__main__":
    main()
