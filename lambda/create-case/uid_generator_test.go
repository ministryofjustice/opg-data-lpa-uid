package main

import (
	"github.com/stretchr/testify/assert"
	"regexp"
	"testing"
)

func TestGenerateUID(t *testing.T) {
	uid, err := generateUID()
	assert.Nil(t, err)

	m, err := regexp.Match(`^MTEST-[346789QWERTYUPADFGHJKLXCVBNM]{4}(?:-[346789QWERTYUPADFGHJKLXCVBNM]{4}){2}$`, []byte(uid))
	assert.Nil(t, err)
	assert.True(t, m)
}

func TestGenerateChecksum(t *testing.T) {
	testData := []struct {
		uid              string
		expectedCheckSum string
	}{
		{uid: "FH4DE694A8L", expectedCheckSum: "C"},
		{uid: "C9N9QL78D78", expectedCheckSum: "4"},
		{uid: "7AF39NH67NQ", expectedCheckSum: "V"},
		{uid: "F8FN8H4RX7D", expectedCheckSum: "U"},
		{uid: "YW47JH3GM4D", expectedCheckSum: "4"},
	}
	for _, tt := range testData {
		t.Run("", func(t *testing.T) {
			assert.Equal(t, tt.expectedCheckSum, generateChecksum(tt.uid))
		})
	}
}

func TestValidateChecksum(t *testing.T) {
	testData := []struct {
		uid      string
		expected bool
	}{
		{uid: "FH4DE694A8LC", expected: true},
		{uid: "C9N9QL78D784", expected: true},
		{uid: "WU4HT9BV94BF", expected: true},
		{uid: "7AF39NH67NQP", expected: false},
		{uid: "F8FN8H4RX7D3", expected: false},
		{uid: "GV8CW8F3V94X", expected: false},
	}
	for _, tt := range testData {
		t.Run("", func(t *testing.T) {
			assert.Equal(t, tt.expected, validateChecksum(tt.uid))
		})
	}
}

func TestHypenateUID(t *testing.T) {
	assert.Equal(t, "FH4D-E694-A8LC", hyphenateUID("FH4DE694A8LC"))
}
