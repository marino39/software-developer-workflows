package calc

// Sum returns the sum of all elements in xs.
func Sum(xs []int) int {
	total := 0
	for i := 0; i < len(xs); i++ {
		total += xs[i]
	}
	return total
}
