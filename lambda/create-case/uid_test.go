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
	assert.Equal(t, "M-3779-9919-9529", formatUID(1))
	assert.Equal(t, "M-3983-7994-6950", formatUID(2))
	assert.Equal(t, "M-0154-0598-2177", formatUID(572))
	assert.Equal(t, "M-1543-5537-7595", formatUID(12345678901))
	assert.Panics(t, func() { formatUID(1000_0000_0000) })

	assert.True(t, checksumValid("M-1234-5678-9018"))
}
