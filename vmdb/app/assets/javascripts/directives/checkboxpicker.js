miqAngularApplication.directive('checkboxpicker', function() {
  return {
    require: 'ngModel',
      link: function (scope, elem, attr, ctrl) {
        scope.attrName = attr.checkboxpicker;
        scope.$watch(attr.ngModel, function() {
          if((ctrl.$modelValue != undefined && scope.afterGet) || scope.formId == "new") {
            $('#' + ctrl.$name).checkboxpicker();
          }
        });
      }
  }
});
