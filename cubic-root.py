import math
import numpy

def cube_alg(x):
    return math.floor(numpy.cbrt(x))

def cube_hw(x):
    y = 0
    b = 0
    for s in range(30, -3, -3):
        print("-=-=-=-=-=-=-=-=-")
        print(" s:", s, end=" ")
        print(" y:", y, end=" ")
        y = 2*y
        print(" 2y:", y, end=" ")
        temp1 = (y + 1)
        print(" temp1:", temp1, end=" ")
        temp2 = (y * temp1)
        print(" temp2:", temp2, end=" ")
        temp3 = 3 * temp2
        print(" temp3:", temp3, end=" ")
        b = temp3 + 1
        print(" b:", b, end=" ")
        b = (2*y + 1) * (2 * y) * 3 + 1
        b = b << s
        print(" b<<:", b, end=" ")
        if (x >= b):
            print(" x>=b", end=" ")
            x = x - b
            print(" x:",x,end=" ")
            y = y + 1
        print()
    return y

# Test
for x in range(0, 5, 1):
    x = 6
    a = pow(x, 3)
    alg_val = cube_alg(a)
    hw_val = cube_hw(a)
    if (alg_val == hw_val):
        print("Correct! x: ", str(a).ljust(6), "; y: ", str(hw_val).ljust(6))
    else:
        print("ERROR! x: ", str(a).ljust(6), "; y(model): ", str(alg_val).ljust(6), "; y(hw): ", hex(hw_val).ljust(6))
    break