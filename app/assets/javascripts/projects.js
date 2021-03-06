
$(document).on("turbolinks:load ready", function(){
  const CATALOGUE_URL = 'http://localhost:4000';
  const PROJECT = gon.project;
  const INTERVAL = 10000;

  initNetwork(gon.networkData);
  keepRefreshing(INTERVAL, gon.incidents);


  function keepRefreshing(interval, incidents = {alerts: [], warnings: []}) {
    window.setTimeout(() => {
      refreshIncidents(incidents, refreshNetwork).then(currentIncidents => {
        keepRefreshing(interval, currentIncidents);
      });
    }, interval);
  }

  function initNetwork(networkData){
    let container = document.getElementById('network');
    let network = new vis.Network(
      container,
      {nodes: networkData.nodes, edges: networkData.edges},
      networkData.options
    );
  }

  function refreshIncidents(oldIncidents, onChange) {
    console.log('refreshing incidents');
    return $.get( CATALOGUE_URL + '/projects/' + PROJECT + '/incidents.json', function( currentIncidents ) {
      if(incidentsHaveChanged(oldIncidents, currentIncidents)){
        let container = $('.incidents-container').find('section').first();

        if(currentIncidents.alerts.length > 0 || currentIncidents.warnings.length > 0){
          let alerts = currentIncidents.alerts.map(renderAlert);
          let warnings = currentIncidents.warnings.map(renderWarning);
          container.html(alerts + warnings);
        }else{
          container.html(renderNoAlertsMessage());
        }

        onChange();
      }

      return currentIncidents;
    });
  }

  function refreshNetwork(){
    $.get( CATALOGUE_URL + '/projects/' + PROJECT + '/health.json', function( networkData ) {
      initNetwork(networkData);
    });
  }

  function incidentsHaveChanged(old, current){
    if(old.alerts.length != current.alerts.length || old.warnings.length != current.warnings.length) {
      return true;
    }
    old.alerts.forEach((incident, idx) => {
      let currentIncident = current.alerts[idx];
      if(incident.name != currentIncident.name) {
        return true;
      }
    });
    old.warnings.forEach((incident, idx) => {
      let currentIncident = current.warnings[idx];
      if(incident.name != currentIncident.name) {
        return true;
      }
    });

    return false;
  };

  function renderWarning(data) {
    return renderIncident(data, 'warning');
  }

  function renderAlert(data) {
    return renderIncident(data, 'alert');
  }

  function renderIncident(data, incidentClass) {
    return `
 <article class="column column-block">
   <div class="incident ${incidentClass}">
      <div class="incident__content">
        <h2 class="title incident__content__title">${data.name}</h2>
      </div>
    </div>
</article>`;
  }

  function renderNoAlertsMessage() {
    return '<h3> Everything is up and running. </h3>';
  }

});
