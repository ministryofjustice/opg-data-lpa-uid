package main

import (
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
)

func checksumValid(s string) bool {
	s = strings.ReplaceAll(s[2:], "-", "")

	var interim byte
	for _, c := range []byte(s) {
		interim = dammTable[interim][c-'0']
	}
	return interim == 0
}

func TestFormatUID(t *testing.T) {
	assert.Equal(t, "M-0000-0000-0646", formatUID(1))
	assert.Equal(t, "M-0000-0000-1170", formatUID(2))
	assert.Equal(t, "M-0000-0030-3274", formatUID(572))
	assert.Equal(t, "M-5432-0981-7705", formatUID(12345678901))
	assert.Panics(t, func() { formatUID(1000_0000_0000) })

	assert.True(t, checksumValid("M-1234-5678-9018"))
}
