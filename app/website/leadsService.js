angular.module('crudApp')
    .service('LeadsService', ['$http', function($http) {
        const APIrootURL = "/leads";
        return {
            getLeads: getLeads,
            updateLead: updateLead,
            createLead: createLead,
            deleteLead: deleteLead,
            closeDeal: closeDeal,
        }

    function getLeads() {
        var req = {
            method: 'GET',
            url: APIrootURL,
        }
        return $http(req).then(successCallback, rejectedCallback_FullResponse);
    }

    function updateLead(idx, lead) {
        var req = {
            method: 'PUT',
            url: APIrootURL  +"/"+ idx,
            data: JSON.stringify(lead)
        }
        return $http(req).then(successCallback, rejectedCallback_FullResponse);
    }

    function createLead(lead) {
        var req = {
            method: 'POST',
            url: APIrootURL,
            data: JSON.stringify(lead)
        }
        return $http(req).then(successCallback, rejectedCallback_FullResponse);
    }

    function deleteLead(idx) {
        var req = {
            method: 'DELETE',
            url: APIrootURL +"/"+ idx,
        }
        return $http(req).then(successCallback, rejectedCallback_FullResponse);
    }

    function closeDeal(idx) {
        var req = {
            method: 'POST',
            url: APIrootURL +"/close/"+ idx,
        }
        return $http(req).then(successCallback, rejectedCallback_FullResponse);
    }

    function closeDeal(dealId) {
            var req = {
                method: 'POST',
                url: APIrootURL + '/close/' + dealId,

            }
            return $http(req).then(successCallback, rejectedCallback_FullResponse);
        }
    /***   genric handler for success operation     **/
    function successCallback(response) {
        return response.data;
    }

    function rejectedCallback_FullResponse(response) {
        return response;
    }

}]);
