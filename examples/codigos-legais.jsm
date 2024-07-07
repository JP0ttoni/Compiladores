float absolute(float a) {
    if (a < 0) {
        return -a
    }

    return a
}

float ln(float a) {
    if (a <= 0) {
        return 0.0
    }

    var result = 0.0
    var term = (a - 1) / (a + 1)
    var termSquared = term * term
    var num = term
    var denom = 1.0

    for (var i = 1; i < 100; i = i + 1) {
        result = result + num / denom
        num = num * termSquared
        denom = denom + 2.0
    }

    return 2.0 * result
}

float exp(float x) {
    var result = 1.0
    var term = 1.0

    for (var i = 1; i < 100; i = i + 1) {
        term = term * x / i
        result = result + term
    }

    return result
}

float pow(float base, float expoent) {
    if (expoent == 0) {
        return 1.0
    }

    if (base == 0) {
        return 0.0
    }

    var result = 1.0
    var positivo = absolute(expoent)
    var intPart = positivo as int
    var fractPart = positivo - intPart

    for (var i = 0; i < intPart; i = i + 1) {
        result = result * base
    }

    if (fractPart > 0) {
        result = result * exp(fractPart * ln(base))
    }

    if (expoent < 0) {
        return 1.0 / result
    }

    return result
}

println("O resultado de 2^3 é " + pow(2.0, 3.0))
println("O resultado de 2^0 é " + pow(2.0, 0.0))
println("O resultado de 0^2 é " + pow(0.0, 2.0))
println("O resultado de 2^-3 é " + pow(2.0, -3.0))
println("O resultado de 0^-3 é " + pow(0.0, -3.0))
