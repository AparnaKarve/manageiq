ManageIQ.angular.app = angular.module('ManageIQ', [
  'ui.bootstrap',
  'patternfly',
  'frapontillo.bootstrap-switch',
  'angular.validators',
  'miq.api',
  'templates'
]);
miqHttpInject(ManageIQ.angular.app);

ManageIQ.angular.rxSubject = new Rx.Subject();

function miqHttpInject(angular_app) {
  angular_app.config(['$httpProvider', function($httpProvider) {
    $httpProvider.defaults.headers.common['X-CSRF-Token'] = function() {
      return $('meta[name=csrf-token]').attr('content');
    };
  }]);

  return angular_app;
}

function miq_bootstrap(selector, app) {
  app = app || 'ManageIQ';

  return angular.bootstrap($(selector), [app], { strictDi: true });
}

function miqCallAngular(data) {
  ManageIQ.angular.scope.$apply(function() {
    ManageIQ.angular.scope[data.name].apply(ManageIQ.angular.scope, data.args);
  });
}

function sendDataWithRx(data) {
  ManageIQ.angular.rxSubject.onNext(data);
}
