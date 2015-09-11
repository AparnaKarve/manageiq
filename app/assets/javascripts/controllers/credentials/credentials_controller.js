ManageIQ.angularApplication.controller('credentialsController', ['$http', '$scope', '$attrs', 'miqService', function($http, $scope, $attrs, miqService) {
  var init = function() {

    $scope.$on('resetClicked', function(e) {
      $scope.resetClicked();
    });

    ManageIQ.angularApplication.$credentialsScope = $scope;

    if ($scope.$parent.formId == 'new') {
      $scope.newRecord = true;
      $scope.bChangeStoredPassword = undefined;
      $scope.bCancelPasswordChange = undefined;
    }
    else {
      $scope.newRecord = false;
      $scope.bChangeStoredPassword = false;
      $scope.bCancelPasswordChange = false;
    }
  };

  $scope.changeStoredPassword = function() {
    $scope.bChangeStoredPassword = true;
    $scope.bCancelPasswordChange = false;
  };

  $scope.cancelPasswordChange = function() {
    $scope.bCancelPasswordChange = true;
    $scope.bChangeStoredPassword = false;
  };

  $scope.showVerify = function() {
    return $scope.newRecord || $scope.bChangeStoredPassword;
  }

  $scope.initialPasswordStateForExistingRecords = function() {
    return !$scope.newRecord && !$scope.bChangeStoredPassword;
  }

  $scope.resetClicked = function() {
    $scope.cancelPasswordChange();
  }

  init();
}]);

