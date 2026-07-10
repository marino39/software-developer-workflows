package cart

// discountPercent reduces total by pct percent — a multiplicative discount.
// It scales with the total and rounds the deducted amount down (integer division),
// so it can never drive the total below zero for a valid percentage.
func discountPercent(total, pct int) int {
	return total - (total*pct)/100
}

// discountFlat reduces total by a fixed number of cents — a subtractive discount.
// It does not scale with the total, and it clamps to zero so a large flat amount
// never yields a negative total.
func discountFlat(total, amount int) int {
	if amount > total {
		return 0
	}
	return total - amount
}
