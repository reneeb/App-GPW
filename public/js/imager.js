var paw_image_tree = [
    {
        text: '/',
        id: 'root',
        data : 'test',
        children: [
            {
                text : 'Test',
                id : 'root-Test'
            }
        ]
    }
];

$(document).ready( function() {
    console.debug( 'loaded...');
    init_dirtree();
});

function init_dirtree () {
    $('#dirtree').jstree({ core: { data : {
        url : function(node) {
            return "/tree/" + node.id;
        },
        data : function(node) {
            return { 'id' : node.id };
        }
    } } });

    $('#dirtree').on( 'select_node.jstree', function( e, data ) {
        console.debug( data );
        console.debug( 'selected node' );
        data.node.children = [
            { id: 'h2', text: 'jasdl' }
        ];
    });

//    $('#dirtree').trigger('redraw.jstree');
}
