RemitRailsExample::Application.routes.draw do
  resources "payments"
  root :to => "payments#new"
end
