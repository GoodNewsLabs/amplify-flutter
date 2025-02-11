exports.handler = async (event) => {
  if (event.request.session.length == 1 && event.request.session[0].challengeName == 'SRP_A') {
    event.response.issueTokens = false;
    event.response.failAuthentication = false;
    event.response.challengeName = 'CUSTOM_CHALLENGE';
  } else if (event.request.session.length == 2 && event.request.session[1].challengeName == 'CUSTOM_CHALLENGE' && event.request.session[1].challengeResult == true) {
      event.response.issueTokens = true;
      event.response.failAuthentication = false;
  } else {
      event.response.issueTokens = false;
      event.response.failAuthentication = true;
  }
  return event;
};
