miqAngularApplication.controller('DatepickerCtrl', function ($scope) {
  $scope.minDate = new Date();

  $scope.disabled = function(date, viewDate, mode) {
    disabledDate = new Date($scope.$parent.angularForm[viewDate].$viewValue);

    if($scope.$parent.angularForm[viewDate].$untouched) {
      return ( mode === 'day' && (disabledDate.getUTCDate() === date.getDate()) &&
                              disabledDate.getUTCMonth() === date.getMonth() &&
                              disabledDate.getUTCFullYear() === date.getFullYear())
    }
    else
      return null;
  };

  $scope.open = function($event) {
    $event.preventDefault();
    $event.stopPropagation();

    $scope.opened = true;
  };
});