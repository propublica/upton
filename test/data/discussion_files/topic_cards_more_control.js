propublica.views.gi_topicCardsMoreControl = propublica.Deferrable.extend({
    scope: 'div.topic-wrapper',
    tag: 'a.action-button',

    bindings: {
        'click' : 'dispatch'
    },

    render: function() {
    },

    dispatch: function(e) {
        e.preventDefault();
        console.log('!');
        var sectionId   = $('section.action-cards', this.scope).attr('section_id'),
            filters     = {topic:sectionId, type: 'all'};

        $('section.action-cards', this.scope).trigger('more', filters);
    }
});
