%% comentario maneiro no código

int test(int a, int b, int c, int d) {
    return a * 2 + b + c + d * 5
}

int test(int a, int b, int c) {
    return a * 2 + b + c
}

int test(int a, int b) {
    var result = 0;

    for (var i = a; i <= b; i = i + 1) {
        result = result + b;
    }

    return result;
}

var a = test(1, 2, 3, 1)
println(a)

var b = test(1, 2, 3)
println(b)

println(test(1, 5))