ManageIQ.angularApplication.directive('formButtons', function() {
  return {
    restrict: 'E',
    scope: false,
    controller: 'buttonGroupController',
    templateUrl: 'buttons.html'
  };
});
