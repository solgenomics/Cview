use strict;
use Module::Build;

my $build = Module::Build->new(
    dist_name          => 'Cview',

    # version number comes from this module
    module_name        => 'CXGN::Cview::MapFactory',

    dist_author        => 'Sol Genomics Network',
    dist_abstract      => 'a comparative map viewer',
    license            => 'perl',
    create_makefile_pl => 'passthrough',

    recursive_test_files => 1,

    build_requires => {
        #'CXGN::DB::Connection' => 0,
        'Test::More'           => 0,
    },
    requires => {

        # depend on all of bioperl, because
        'Bio::Root::Version' => '1.5.2',
        #'Bio::DB::GFF' => 0,
        #'Bio::Restriction::Analysis' => 0,
        #'Bio::SeqIO' => 0,

        #     'CXGN::Configuration' => 0,
        #     'CXGN::Cview' => 0,
        #     'CXGN::Cview::Chromosome::AGP' => 0,
        #     'CXGN::Cview::Chromosome::IL' => 0,
        #     'CXGN::Cview::Chromosome::ITAG' => 0,
        #     'CXGN::DB::Connection' => 0,
        #     'CXGN::DB::Object' => 0,
        #     'CXGN::Genomic::BACMarkerAssoc' => 0,
        #     'CXGN::Genomic::Clone' => 0,
        #     'CXGN::ITAG::Release' => 0,
        #     'CXGN::Login' => 0,
        #     'CXGN::Map' => 0,
        #     'CXGN::Map::Tools' => 0,
        #     'CXGN::Marker::Tools' => 0,
        #     'CXGN::Page' => 0,
        #     'CXGN::Page::FormattingHelpers' => 0,
        #     'CXGN::People' => 0,
        #     'CXGN::People::BACStatusLog' => 0,
        #     'CXGN::People::UserMap' => 0,
        #     'CXGN::Tools::WebImageCache' => 0,
        #     'CXGN::VHost' => 0,

        'File::Temp'   => 0,
        'List::Util'   => 0,
    },

);
$build->create_build_script;
