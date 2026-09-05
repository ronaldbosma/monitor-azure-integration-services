//=============================================================================
// Service Bus Entities: topics, subscriptions and queues
//=============================================================================

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the Service Bus namespace')
param serviceBusNamespaceName string

//=============================================================================
// Existing Resources
//=============================================================================

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2026-01-01' existing = {
  name: serviceBusNamespaceName
}

//=============================================================================
// Resources
//=============================================================================

resource deletedMoviesTopic 'Microsoft.ServiceBus/namespaces/topics@2026-01-01' = {
  name: 'deleted-movies'
  parent: serviceBusNamespace
}

resource functionAppSubscriptionOnDeletedMoviesTopic 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2026-01-01' = {
  name: 'function-app'
  parent: deletedMoviesTopic
}

resource recalculateMovieRatingQueue 'Microsoft.ServiceBus/namespaces/queues@2026-01-01' = {
  name: 'recalculate-movie-rating'
  parent: serviceBusNamespace
}
