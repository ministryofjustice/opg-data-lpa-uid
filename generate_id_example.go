package opg_data_lpa_id

import (
	"fmt"
	"math/rand"
	"strconv"
	"time"
)

func generateID() string {
	allChars := []string{"3", "4", "6", "7", "8", "9", "Q", "W", "E", "R", "T", "Y", "U", "P", "A", "D", "F", "G", "H", "J", "K", "L", "X", "C", "V", "B", "N", "M"}
	numChars := []string{"3", "4", "6", "7", "8", "9"}
	generator := rand.New(rand.NewSource(rand.Int63() * time.Now().UnixNano()))

	var v int
	id := "M-"
	lettersInSequence := 0

	for i := 1; i <= 12; i++ {
		if lettersInSequence == 2 {
			v = generator.Intn(len(numChars)) // if there has been 2 letters in sequence, pick from numbers next to avoid bad words being created
			lettersInSequence = 0
		} else {
			v = generator.Intn(len(allChars))
			if _, err := strconv.Atoi(allChars[v]); err != nil {
				lettersInSequence++
			} else {
				lettersInSequence = 0 // if it picks a number, reset the letters in sequence count
			}
		}

		id = id + allChars[v]
	}

	return id
}

func main() {
	for i := 1; i <= 5; i++ { // generate 5 IDs to show example output
		fmt.Println(generateID())
	}

	// example output:
	// M-CP8V3CU6QN8D
	// M-8JD9V97HN8W4
	// M-F6K4HF9HW6PA
	// M-F8VG8T47RX9F
	// M-G96K7EM7AR4P
}
