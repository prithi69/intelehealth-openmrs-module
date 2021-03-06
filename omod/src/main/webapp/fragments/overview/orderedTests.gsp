<%
    ui.includeJavascript("intelehealth", "angular/angular.min.js")
    ui.includeJavascript("intelehealth", "angular/angular.js")
    ui.includeJavascript("intelehealth", "angular-sanitize/angular-sanitize.js")
    ui.includeJavascript("intelehealth", "angular-animate/angular-animate.js")
    ui.includeJavascript("intelehealth", "angular-bootstrap/ui-bootstrap-tpls.js")
%>

<style>

.sr-only {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip: rect(0, 0, 0, 0);
    border: 0
}

.alert {
    padding: 15px;
    margin-bottom: 10px;
    border: 1px solid transparent;
    border-radius: 4px
}
.alert h4 {
    margin-top: 0;
    color: inherit
}
.alert .alert-link {
    font-weight: 700
}
.alert-info {
    color: #31708f;
    background-color: #d9edf7;
    border-color: #bce8f1
}
.alert-info hr {
    border-top-color: #a6e1ec
}
.alert-info .alert-link {
    color: #245269
}
.close {
    float: right;
    font-size: 21px;
    font-weight: 700;
    line-height: 1;
    color: #000;
    text-shadow: 0 1px 0 #fff;
    filter: alpha(opacity=20);
    opacity: .2
}
.close:focus,
.close:hover {
    color: #000;
    text-decoration: none;
    cursor: pointer;
    filter: alpha(opacity=50);
    opacity: .5
}
button.close {
    -webkit-appearance: none;
    padding: 0;
    cursor: pointer;
    background: 0 0;
    border: 0
}

</style>

<div id="orderedTests" class="long-info-section" ng-controller="OrderedTestsSummaryController">
	<div class="info-header">
		<i class="icon-beaker"></i>
		<h3>Prescribed Tests</h3>
	</div>
	<div class="info-body">
		<input type="text" ng-model="addMe" uib-typeahead="test for test in testlist | filter:\$viewValue | limitTo:8" class="form-control">
		<button type="button" class='btn btn-default' ng-click="addAlert()">Add Test</button>
		<p>{{errortext}}</p>
		<br/>
		<br/>
		<div uib-alert ng-repeat="alert in alerts" ng-class="'alert-' + (alert.type || 'info')" close="closeAlert(\$index)">{{alert.msg}}</div>
	</div>
    <div>
        <a href="#" class="right back-to-top">Back to top</a>
    </div>
</div>

<script>
var app = angular.module('orderedTestsSummary', ['ngAnimate', 'ngSanitize']);

app.factory('OrderedTestsSummaryFactory1', function(\$http, \$filter){
  var patient = "${ patient.uuid }";
  var date = new Date();
  date = \$filter('date')(new Date(), 'yyyy-MM-dd');
  var url = "/" + OPENMRS_CONTEXT_PATH + "/ws/rest/v1/encounter";
      url += "?patient=" + patient;
      url += "&encounterType=" + "d7151f82-c1f3-4152-a605-2f9ea7414a79";
      url += "&fromdate=" + date;
  return {
    async: function(){
      return \$http.get(url).then(function(response){
        return response.data.results;
      });
    }
  };
});

app.factory('OrderedTestsSummaryFactory2', function(\$http){
  var patient = "${ patient.uuid }";
  var url1 = "/" + OPENMRS_CONTEXT_PATH + "/ws/rest/v1/encounter";
  var date2 = new Date();
  var json = {
      patient: patient,
      encounterType: "d7151f82-c1f3-4152-a605-2f9ea7414a79",
      encounterDatetime: date2
  };
  return {
    async: function(){
      return \$http.post(url1, JSON.stringify(json)).then(function(response){
        return response.data.uuid;
      });
    }
  };
});

app.factory('OrderedTestsSummaryFactory3', function(\$http){
  var testurl = "/" + OPENMRS_CONTEXT_PATH + "/ws/rest/v1/concept/98c5881f-b214-4597-83d4-509666e9a7c9";
  return {
    async: function(){
      return \$http.get(testurl).then(function(response){
	var data = [];
	angular.forEach(response.data.answers, function(value, key){
	  data.push(value.display);
	});
        return data;
      });
    }
  };
});

app.controller('OrderedTestsSummaryController', function(\$scope, \$http, \$timeout, OrderedTestsSummaryFactory1, OrderedTestsSummaryFactory2, OrderedTestsSummaryFactory3) {
  \$scope.alerts = [];
  var _selected;
  var patient = "${ patient.uuid }";
  var date2 = new Date();

  var promiseTests = OrderedTestsSummaryFactory3.async().then(function(d){
	return d;
  });

  promiseTests.then(function(x){
	\$scope.testlist = x;
  })

  \$timeout(function () {
        var promise = OrderedTestsSummaryFactory1.async().then(function(d){
                var length = d.length;
                if(length > 0) {
                        angular.forEach(d, function(value, key){
                                \$scope.data = value.uuid;
                        });
                } else {
                        \$scope.data2 = "Created an Encounter";
                        OrderedTestsSummaryFactory2.async().then(function(d2){
                                \$scope.data = d2;
                        })
                };
                return \$scope.data;
        });

        promise.then(function(x){
                \$scope.data3 = x;

                \$scope.respuuid = [];
                \$scope.addAlert = function() {
                        \$scope.errortext = "";
                        if (!\$scope.addMe) {
                                \$scope.errortext = "Please enter text.";
                                return;
                        }
    			if (\$scope.alerts.indexOf(\$scope.addMe) == -1){
    				\$scope.alerts.push({msg: \$scope.addMe})
    				var url2 = "/" + OPENMRS_CONTEXT_PATH + "/ws/rest/v1/obs";
    				\$scope.json = {
         				concept: "23601d71-50e6-483f-968d-aeef3031346d",
         				person: patient,
         				obsDatetime: date2,
         				value: \$scope.addMe,
         				encounter: x
        			}
    				\$scope.addMe = "";
    				\$http.post(url2, JSON.stringify(\$scope.json)).then(function(response){
        				if(response.data)
                				\$scope.statuscode = "Success";
                				\$scope.respuuid.push(response.data.uuid);
    				}, function(response){
                			\$scope.statuscode = "Failed to create Obs";
    				});
    			}
  		};

  		\$scope.closeAlert = function(index) {
    			\$scope.alerts.splice(index, 1);
    			\$scope.errortext = "";
    			var deleteurl = "/" + OPENMRS_CONTEXT_PATH + "/ws/rest/v1/obs/" + \$scope.respuuid[index] + "?purge=true";
    			\$scope.respuuid.splice(index, 1);
			\$http.delete(deleteurl).then(function(response){
				\$scope.statuscode = "Success";
			}, function(response){
				\$scope.statuscode = "Failed to delete Obs";
			});
  		};  
        });
  }, 2000);

});
</script>

<script>
</script>  
