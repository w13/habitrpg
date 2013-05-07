derby = require 'derby'

# Include library components
derby.use require('derby-ui-boot'), {styles: []}
derby.use require '../../ui'
derby.use require 'derby-auth/components'

# Init app & reference its functions
app = derby.createApp module
{get, view, ready} = app

# Translations
i18n = require './i18n'
i18n.localize app,
  availableLocales: ['en', 'he', 'bg']
  defaultLocale: 'en'

h = require './helpers'
h.viewHelpers view

_ = require('underscore')

# ========== ROUTES ==========

get '/', (page, model, params, next) ->
  return page.redirect '/' if page.params?.query?.play?

  # removed force-ssl (handled in nginx), see git for code

  require('./party').partySubscribe page, model, params, next, ->
    model.setNull '_user.apiToken', derby.uuid()

    require('./items').server(model)

    page.render()

# ========== CONTROLLER FUNCTIONS ==========

ready (model) ->
  user = model.at('_user')

  ## Remove corrupted tasks
  _.each ['habits','dailys','todos','rewards'], (type) ->
    _.each user.get(type), (task, i) ->
      user.del("#{type}.#{i}") unless task?.id?

  #set cron immediately
  lastCron = user.get('lastCron')
  user.set('lastCron', +new Date) if (!lastCron? or lastCron == 'new')

  require('./scoring').cron(model)

  require('./character').app(exports, model)
  require('./tasks').app(exports, model)
  require('./items').app(exports, model)
  require('./party').app(exports, model, app)
  require('./profile').app(exports, model)
  require('./pets').app(exports, model)
  require('../server/private').app(exports, model)
  require('./debug').app(exports, model) if model.flags.nodeEnv != 'production'
  require('./browser').app(exports, model, app)
  require('./unlock').app(exports, model)
  require('./filters').app(exports, model)
