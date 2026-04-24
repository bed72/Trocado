typedef DateRangeSelected = void Function(int startDate, int endDate);

typedef NavigateToDateRange =
    void Function({
      int? initialEndDate,
      int? initialStartDate,
      required DateRangeSelected onSelected,
    });
