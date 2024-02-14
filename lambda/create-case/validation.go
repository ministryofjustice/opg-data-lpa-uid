package main

import (
	"fmt"
	"regexp"
	"strings"
)

var rePostcode = regexp.MustCompile(`^[A-Z0-9]{5,7}$`)
var reDateOfBirth = regexp.MustCompile(`^[0-9]{4}-[0-9]{2}-[0-9]{2}$`)

func validate(data Request) (bool, []Error) {
	validationErrors := []Error{}

	if data.Source == "" {
		validationErrors = append(validationErrors, Error{
			Source: "/source",
			Detail: "required",
		})
	} else if data.Source != LpaSourceApplicant && data.Source != LpaSourcePhone {
		validationErrors = append(validationErrors, Error{
			Source: "/source",
			Detail: fmt.Sprintf("must be %s or %s", LpaSourceApplicant, LpaSourcePhone),
		})
	}

	if data.Type == "" {
		validationErrors = append(validationErrors, Error{
			Source: "/type",
			Detail: "required",
		})
	} else if data.Type != LpaTypePersonalWelfare && data.Type != LpaTypePropertyAndAffairs {
		validationErrors = append(validationErrors, Error{
			Source: "/type",
			Detail: fmt.Sprintf("must be %s or %s", LpaTypePersonalWelfare, LpaTypePropertyAndAffairs),
		})
	}

	if data.Donor.Name == "" {
		validationErrors = append(validationErrors, Error{
			Source: "/donor/name",
			Detail: "required",
		})
	}

	if data.Donor.DateOfBirth == "" {
		validationErrors = append(validationErrors, Error{
			Source: "/donor/dob",
			Detail: "required",
		})
	} else if !reDateOfBirth.MatchString(data.Donor.DateOfBirth) {
		validationErrors = append(validationErrors, Error{
			Source: "/donor/dob",
			Detail: "must match format YYYY-MM-DD",
		})
	}

	data.Donor.Postcode = strings.ReplaceAll(data.Donor.Postcode, " ", "")
	if data.Donor.Postcode == "" {
		validationErrors = append(validationErrors, Error{
			Source: "/donor/postcode",
			Detail: "required",
		})
	} else if !rePostcode.MatchString(data.Donor.Postcode) {
		validationErrors = append(validationErrors, Error{
			Source: "/donor/postcode",
			Detail: "must be a valid postcode",
		})
	}

	return len(validationErrors) > 0, validationErrors
}
