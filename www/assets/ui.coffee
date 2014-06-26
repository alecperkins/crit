
{ View, Model, Collection } = Backbone
{ Button, Tags, BaseDoodad, Popover, StringField, Form, List } = Doodad



class ContentObject extends Model
    url: -> @get('url') or window.CONTENT_API_ROOT
    sync: (method, collection, options={}) =>
        options.headers = _.extend {}, options.headers,
            'Authorization' : "Token #{ window.CONTENT_API_TOKEN }"
        return super(method, collection, options)


class ProjectModel extends ContentObject
    defaults:
        type: 'container'
        role: 'project'
        content: []

class ProjectCollection extends Collection
    model: ProjectModel
    url: -> window.CONTENT_API_ROOT
    sync: (method, collection, options={}) =>
        options.data = _.extend {}, options.data,
            role: 'project'
            type: 'container'
        options.headers = _.extend {}, options.headers,
            'Authorization' : "Token #{ window.CONTENT_API_TOKEN }"
        return super(method, collection, options)






# ContentObject model that supports receiving an image file, and stores it
# using FilePicker, then generates the specific sizes we need.
class UploadableImage extends ContentObject

    initialize: ->
        @set(type: 'image')
        @_progress_val = 0


    _emitProgress: (incr_amount) =>
        @_progress_val += incr_amount
        @trigger('progress', @_progress_val)

    upload: (file, callback) ->
        filepicker.store file, {mimetype:'image/*'},
            # onSuccess
            (fp) =>
                @onUploadSuccess(fp, callback)
            ,
            # onError
            (type, message) =>
                log.error type, message
                @trigger('upload:error', type, message)
            ,
            # onProgress
            (percentage) =>
                @trigger('upload:progress', percentage)
                console.log percentage
                @_emitProgress( 0.5 * (percentage/100) - @_progress_val )

    onUploadSuccess: (original_fp, callback) =>
        processing_count = 0

        checkComplete = =>
            @_emitProgress(0.5 / 3)
            if processing_count is 0
                callback?(this)
        filepicker.stat original_fp, {width:true , height:true}, (metadata) =>
            {width,height,size} = metadata
            aspect_ratio = width/height
            processing_count += 1
            @save
                original:
                    s3_key   : original_fp.key
                    mimetype : original_fp.mimetype
                    fp_url   : original_fp.url
                    width    : width
                    height   : height
                    size     : size
                    filename : original_fp.filename
            ,
                success: ->
                    processing_count -= 1
                    checkComplete()

            content = {}

            @trigger('upload:processing')

            processing_count += 1
            filepicker.convert original_fp, {width:1280, height:parseInt(1280/aspect_ratio), fit:'scale',}, (fp) =>
                content['1280'] = 
                    fp_url : fp.url
                    s3_key : fp.key
                    width  : 1280
                    height : parseInt(1280/aspect_ratio)
                    size   : fp.size
                @save
                    content:content
                ,
                    success: =>
                        processing_count -= 1
                        @trigger('upload:processed', '1280')
                        checkComplete()

            processing_count += 1
            filepicker.convert original_fp, {width:640, height:parseInt(640/aspect_ratio), fit:'scale',}, (fp) =>
                content['640'] =
                    fp_url : fp.url
                    s3_key : fp.key
                    width  : 640
                    height : parseInt(640/aspect_ratio)
                    size   : fp.size
                @save
                    content:content
                ,
                    success: =>
                        processing_count -= 1
                        @trigger('upload:processed', '640')
                        checkComplete()


class ImageUploadTrigger extends Button
    progress: true
    variant: 'friendly'
    label: 'Upload Image'

    action: (self) =>
        @_$file.trigger('click')


    constructor: ->
        super(arguments...)
        @reset()

    reset: ->
        @_$file = $('<input type="file">')
        @_$file.on('change', @_startUpload)
        @_upload = new UploadableImage()
        @_upload.on 'progress', (p) =>
            @setProgress(p)
            console.log p
        @enable()
        @setLabel(@label)
        return this

    _startUpload: (e) =>
        file = e.currentTarget.files?[0]
        console.log arguments, file
        if file
            console.log 'starting upload', file
            @setLabel('Uploading...')
            @_upload_is_active = true
            @_upload.upload file, =>
                @trigger('uploaded', @_upload)
                @reset()
        else
            console.log 'resetting'
            @_upload_is_active = false
            @reset()
        return





class Panel extends View
    className: 'Panel'
    initialize: ->
    render: ->
        @$el.empty()
        image_url = @model.get('content')[0]?.original?.url
        if image_url
            @$el.html("<img src='#{ image_url }'>")
            @$el.find('img').draggable
                axis: 'y'
                stop: (e, ui) ->
                    console.log ui
        return this
    setWidth: (w) ->
        @$el.css
            width: "#{ w * 100 }%"
    align: (v) ->
        @$el.css
            top: v


class Panels extends View
    className: 'Panels'
    initialize: ->
        @_panels = []
        @model.on('change', @render)
        @addPanel()

    render: =>
        @$el.empty()
        _.each @_panels, (panel) =>
            @$el.append(panel.render().el)
        return this

    addPanel: =>
        panel = new Panel
            model: @model
        @_panels.push(panel)
        @_resizePanels()
        @$el.append(panel.render().el)
        @_autoAlignPanels()

    _resizePanels: ->
        _.invoke(@_panels, 'setWidth', 1 / @_panels.length)

    _autoAlignPanels: ->
        height = @$el.height() * 0.95
        _.each @_panels, (panel, i) ->
            panel.align(-1 * height * i)

    removePanel: =>
        panel = @_panels.pop()
        panel.$el.remove()
        @_resizePanels()

class ProjectSelectorItem extends View
    tagName: 'LI'
    render: ->
        @$el.html(@model.get('title'))
        return this
    events:
        'click': '_triggerSelect'
    _triggerSelect: =>
        console.log 'selecting', @model
        @trigger('select')

class ProjectSelector extends View
    tagName: 'UL'
    initialize: ->
        @collection.on('sync', @render)
    render: =>
        @$el.empty()
        @collection.each (project) =>
            project_list_item = new ProjectSelectorItem
                model: project
            @$el.append(project_list_item.render().el)
            project_list_item.on 'select', =>
                @model.set(project.toJSON())
                project_select_popover.hide()
        return this





active_project = new ProjectModel()
project_collection = new ProjectCollection()
project_collection.fetch()

upload_trigger = new ImageUploadTrigger()
upload_trigger.on 'uploaded', (image_obj) ->
    active_project.save
        content: [image_obj.id]
    upload_trigger.disable()
if active_project.get('content')?.length > 0
    upload_trigger.disable()


project_info_form = new Form
    model: active_project
    content: [
        new StringField
            name: 'title'
            label: 'Title'
        new List
            name: 'notes'
            label: 'Notes'
    ]

project_info_form.render()
project_info_popover = new Popover
    type: 'modal'
    content: [
        project_info_form
    ]
    confirm: 'Save'
    dismiss: 'Cancel'

project_info_popover.on 'confirm', ->
    active_project.save()

add_panel_trigger = new Button
    type: 'icon'
    variant: 'action-plus'
    action: -> panels.addPanel()

remove_panel_trigger = new Button
    type: 'icon'
    variant: 'action-minus'
    action: -> panels.removePanel()

project_info_trigger = new Button
    label: 'i'
    action: project_info_popover.toggle

project_controls = new Tags.DIV
    id: 'project_controls'
    content: [
            add_panel_trigger
            remove_panel_trigger
            project_info_trigger
            upload_trigger
        ]







project_selector = new ProjectSelector
    model: active_project
    collection: project_collection

project_select_popover = new Popover
    content: [project_selector]
    type: 'modal'
    dismiss: new Button
        type: 'text-bare'
        label: 'Nevermind'

project_select_trigger = new Button
    type: 'icon'
    variant: 'default-right'
    action: project_select_popover.toggle

app_controls = new Tags.DIV
    id: 'app_controls'
    content: [
            project_select_trigger
        ]


controls = new Tags.DIV
    id: 'controls'
    content: [
        project_controls
        app_controls
    ]

panels = new Panels
    id: 'panels'
    model: active_project

app = new Tags.DIV
    id: 'app'
    content: [
        panels
        controls
    ]

$('body').append(app.el)
