// expect_lint: avoid-inconsistent-digit-separators
const uneven = 1_000_00;
// expect_lint: avoid-inconsistent-digit-separators
const alsoUneven = 12_34_5;
// expect_lint: avoid-inconsistent-digit-separators
const hexUneven = 0xFF_FFF_FF;

const thousands = 1_000_000;
const leadingShorter = 12_345_678;
const pairs = 0xFF_FF_FF;
const plain = 100000;
const noSeparators = 0xFFFFFF;
