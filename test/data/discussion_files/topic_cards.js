propublica.views.gi_topic_cards = propublica.View.extend({
    scope: 'div.topic-wrapper',
    tag: 'section',
    cssClass: 'action-cards',

    bindings: {
        'more'   : 'more',
        'all'    : 'render'
    },

    render: function() {
        var sectionId   = $('section.action-cards', this.scope).attr('section_id'),
            filters     = {topic:sectionId, type: 'all'};
        this.pullData(filters);
    },

    more: function(e, filters) {
        this.pullData(filters, true);
    },

    pullData: function(filters, showMore) {
        var self        = this,
            url         = window.location.href,
            context     = (url.indexOf('item') > -1) ? 'single' : 'topic',
            entryId     = $('section.action-cards', this.scope).attr('entry_id'),
            limit       = '4',
            vals        = _.values(filters),
            filterStr   = _.without(vals, 'all').join('+'),
            showing     = self.el.children('section').length;

        $('section.action-cards section', self.scope).animate({opacity:'0.3'}, 400);

        if (showMore === true) limit = showing += 4;
        if (entryId === undefined) entryId = '';
        //filterStr = filterStr + '/' + limit + '/' + context + '/' + entryId;
        //$.get('/getinvolved/cards_ajax/'+filterStr, function(data) {
        var postData = {
            'cats'    : filterStr,
            'limit'   : limit,
            'context' : context,
            'not'     : entryId
        };
        var id = (context == 'single') ? entryId : '';
        $.post('/getinvolved/cards_ajax_post/'+id, postData).done(function(data) {
            data = data.replace(/\n\n/gi, '');
            var $counts     = $(data).get(0), // Counts tag is always first
                counts      = $($counts).text().split(':'),
                showing     = parseInt(counts[0], 10),
                total       = parseInt(counts[1], 10),
                $button     = $('section.action-cards', self.scope).find('a.action-button');
            data = _.rest($(data)); // Remove the counts tag
            console.log(counts);
            if (total <= 4 || showing >= total)
                $button.hide();
            else
                $button.show();
            self.el.children('section').remove();
            self.el.children('header').after(data);
            self.el.children('section').animate({opacity:'1'}, 100);
        });
    }
});
