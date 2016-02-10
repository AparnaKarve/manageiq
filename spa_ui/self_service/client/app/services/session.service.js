(function() {
  'use strict';

  angular.module('app.services')
    .factory('Session', SessionFactory);

  /** @ngInject */
  function SessionFactory($http, moment, $sessionStorage, gettextCatalog, lodash) {
    var model = {
      token: null,
      user: {}
    };

    var service = {
      current: model,
      create: create,
      destroy: destroy,
      active: active,
      currentUser: currentUser,
      loadUser: loadUser,
    };

    destroy();

    return service;

    function create(data) {
      model.token = data.auth_token;
      $http.defaults.headers.common['X-Auth-Token'] = model.token;
      $sessionStorage.token = model.token;
    }

    function destroy() {
      model.token = null;
      model.user = {};
      delete $http.defaults.headers.common['X-Auth-Token'];
      delete $sessionStorage.token;
    }

    function loadUser() {
      return $http.get('/api')
        .then(function(response) {
          currentUser(response.data.identity);
          userFeatures(); // use features instead of identity

          var locale = response.data.settings && response.data.settings.locale;
          gettextCatalog.loadAndSet(locale);
        });
    }

    function currentUser(user) {
      if (angular.isDefined(user)) {
        model.user = user;
      }

      return model.user;
    }

    function userFeatures() {
      var hardcodedUserFeatures = [
        {'id': 10000000004060, 'identifier': "service_edit", 'parent_id': 10000000004059},
        {'id': 10000000004061, 'identifier': "service_delete", 'parent_id': 10000000004059},
        {'id': 10000000004058, 'identifier': "service_view", 'parent_id': 10000000004056},
        {'id': 10000000004056, 'identifier': "service", 'parent_id': 10000000003876}
      ];

      var serviceFeature = lodash.find(hardcodedUserFeatures, function(o) {
        return o.identifier === "service";
      });
      var serviceCatalogFeature = lodash.find(hardcodedUserFeatures, function(o) {
        return o.identifier === "svc_catalog_accord";
      });
      var requestFeature = lodash.find(hardcodedUserFeatures, function(o) {
        return o.identifier === "miq_request";
      });

      var features = {
        dashboard: {show: angular.isDefined(serviceFeature) ||
                          angular.isDefined(requestFeature) ||
                          angular.isDefined(serviceCatalogFeature)},
        services: {show: angular.isDefined(serviceFeature)},
        requests: {show: angular.isDefined(requestFeature)},
        marketplace: {show: angular.isDefined(serviceCatalogFeature)}
      };
      model.features = features;

      return model.features;
    }

    // Helpers

    function active() {
      // may not be current, but if we have one, we'll rely on API 401ing if it's not
      return model.token;
    }
  }
})();
