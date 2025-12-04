angular.module('crudApp', [])
        .controller('CrudController', ['$scope', 'LeadsService', function($scope, LeadsService) {
            // Initialize data
            window.MY_SCOPE = $scope;

            $scope.users = [];
            $scope.currentUser = {};
            $scope.isEditing = false;
            $scope.showDeleteModal = false;
            $scope.userToDelete = null;
            $scope.message = {};
            $scope.searchText = '';
            $scope.filteredUsers = [];

            $scope.saveUser = function() {
            if ($scope.userForm.$valid) {
                if ($scope.isEditing) {
                    LeadsService.updateLead($scope.currentUserIdx, $scope.currentUser)
                        .then(function(response) {
                            $scope.resetForm();
                            $scope.GetLeads();
                            console.log('User updated successfully!', 'success');
                        })
                        .catch(function(error) {
                            console.error('Error updating user: ' + error.data.error, 'error');
                        });
                } else {
                    LeadsService.createLead($scope.currentUser)
                        .then(function(response) {
                            $scope.resetForm();
                            $scope.GetLeads();
                            console.log('User created successfully!', 'success');
                        })
                        .catch(function(error) {
                            console.error('Error adding user: ' + error.data.error, 'error');
                        });
                }
            }
        };


        $scope.editUser = function(idx, user) {
            $scope.isEditing = true;
            $scope.currentUser = angular.copy(user);
            $scope.currentUserIdx = idx; // Store the index or ID for updating
            if ($scope.userForm) {
                $scope.userForm.$setPristine();
            }
        };


        // Delete User
        $scope.deleteUser = function(idx) {
            LeadsService.deleteLead(idx)
                .then(function(response) {
                    $scope.GetLeads();
                })
                .catch(function(error) {
                    console.error('Error deleting user: ' + error.data.error, 'error');
                });
        };

        // Gets the user data from the server
        $scope.GetLeads = function() {
            LeadsService.getLeads()
                .then(function(response) {
                    $scope.usersOBJ = response;
                    $scope.filteredUsers = $scope.usersOBJ;
                })
                .catch(function(error) {
                    console.error('Error loading users: ' + error.data.error, 'error');
                });
        };

        $scope.closeDeal = function(dealID) {
            LeadsService.closeDeal(dealID)
                .then(function(response) {
                  $scope.GetLeads(); 
                })
                .catch(function(error) {
                    console.error('Error loading users: ' + error.data.error, 'error');
                });
        };

        $scope.resetForm = function() {
            $scope.currentUser = {};
            $scope.currentUserIdx = null;
            $scope.isEditing = false;
            if ($scope.userForm) {
                $scope.userForm.$setPristine();
                $scope.userForm.$setUntouched();
            }
            $scope.message = {};
        };

            $scope.init = function() {
                $scope.GetLeads();
            }

            $scope.init();
        }]);
