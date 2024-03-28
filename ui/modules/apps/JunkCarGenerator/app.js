angular.module('beamng.apps')
  .directive('junkCarGenerator', [function () {
    return {
      templateUrl:
        '/ui/modules/apps/junkCarGenerator/app.html',
      replace: true,
      restrict: 'EA',
      link: function (scope, element, attrs) {
        scope.setting_b1 = true;
        scope.setting_b2 = false;
        scope.setting_b3 = true;
        scope.setting_b4 = false;
        scope.setting_b5 = true;
        scope.setting_b6 = false;

        scope.setting_n1 = 1;
        scope.setting_n2 = 2;
        scope.setting_n3 = 3;
        scope.setting_n4 = 4;
        scope.setting_n5 = 5;
        scope.setting_n6 = 6;
       
        scope.spawnRandom = () => {
          bngApi.engineLua(`print("test")`)
          bngApi.engineLua(`print(${scope.setting_b1})`)
          bngApi.engineLua(`print(${scope.setting_n1})`)
        }

        scope.$on('$destroy', function () {
          StreamsManager.remove(['sensors'])
        })
      }
    }
  }
  ]);