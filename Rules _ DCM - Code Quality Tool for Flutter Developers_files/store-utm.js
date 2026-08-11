const params = new Proxy(new URLSearchParams(window.location.search), {
  get: (searchParams, prop) => searchParams.get(prop),
});

const source = params.utm_source;
const medium = params.utm_medium;
const campaign = params.utm_campaign;

const savedUtm = JSON.parse(localStorage.getItem('utm'));
if (savedUtm == null) {
  const newUtm = {
    source: source != null ? [source] : [],
    medium: medium != null ? [medium] : [],
    campaign: campaign != null ? [campaign] : [],
  };

  localStorage.setItem('utm', JSON.stringify(newUtm));
} else {
  if (source != null) {
    savedUtm.source.push(source);
  }
  if (medium != null) {
    savedUtm.medium.push(medium);
  }
  if (campaign != null) {
    savedUtm.campaign.push(campaign);
  }

  localStorage.setItem('utm', JSON.stringify(savedUtm));
}
