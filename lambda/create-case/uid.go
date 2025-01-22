package main

import (
	"fmt"
	"strings"
)

var (
	a   = 53
	c   = 11
	max = 9999_9999_999
)

var dammTable = [10][10]byte{
	{0, 3, 1, 7, 5, 9, 8, 6, 4, 2},
	{7, 0, 9, 2, 1, 5, 4, 8, 6, 3},
	{4, 2, 0, 6, 8, 7, 1, 3, 5, 9},
	{1, 7, 5, 0, 9, 8, 3, 4, 2, 6},
	{6, 1, 2, 3, 0, 4, 5, 9, 7, 8},
	{3, 6, 7, 4, 2, 0, 9, 5, 8, 1},
	{5, 8, 6, 9, 7, 2, 0, 1, 3, 4},
	{8, 9, 4, 5, 3, 6, 2, 0, 1, 7},
	{9, 4, 3, 8, 6, 1, 7, 2, 0, 5},
	{2, 5, 8, 1, 4, 3, 6, 7, 9, 0},
}

// formatUID converts a sequence number into a formatted UID.
func formatUID(n int) string {
	if n > max {
		panic("maximum uid size exceeded")
	}

	mixed := (a*n + c) % int(max)
	s := fmt.Sprint(mixed)
	s = strings.Repeat("0", 11-len(s)) + s + checksum(s)
	return "M-" + s[0:4] + "-" + s[4:8] + "-" + s[8:12]
}

func checksum(s string) string {
	var interim byte
	for _, c := range []byte(s) {
		interim = dammTable[interim][c-'0']
	}

	return string(interim + '0')
}
