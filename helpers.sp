/**
 * Return the modulo (remainder) of the a / b operation.
 * Should be equivalent of a % b but it's broken as of SourceMod 1.11.0.6964
 * @param a  Numerator
 * @param b  Denominator
 * @return  The result of a % b
 */
public int Modulo(int a, int b) {
    return a - a/b * b;
}