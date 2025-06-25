package event

type Category string

const (
	CategoryLPAStub = Category("CategoryLPAStub")
)

type Measure string

const (
	MeasureCreated = Measure("CREATED")
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
