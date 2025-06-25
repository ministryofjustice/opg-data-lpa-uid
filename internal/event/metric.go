package event

type Category string

const (
	CategoryDraftLPACreated = Category("DraftLPACreated")
)

type Measure string

const (
	MeasureOnlineDonor = Measure("ONLINEDONOR")
	MeasurePaperDonor  = Measure("PAPERDONOR")
)

type Metrics struct {
	Metrics []MetricWrapper `json:"metrics"`
}

type MetricWrapper struct {
	Metric Metric `json:"metric"`
}

type Metric struct {
	Project          string
	Category         string
	Subcategory      Category
	Environment      string
	MeasureName      Measure
	MeasureValue     string
	MeasureValueType string
	Time             string
}
