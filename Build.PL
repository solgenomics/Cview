use Module::Build;
my $class = Module::Build->subclass(
    class => 'Module::Build::SGNSite',
    code  => <<'SUBCLASS',

# build action just runs make on programs
sub ACTION_build {
   my $self = shift;
   $self->SUPER::ACTION_build(@_);
   system "make -C programs";
   $? and die "make failed\n";
}

# disable tests, since they are not self-contained
sub ACTION_test {}

# override install to just copy the whole dir into the install_base
sub ACTION_install {
   my $self = shift;
   $self->SUPER::ACTION_install(@_);

   my @install_dirs = qw|cgi-bin conf documents mason programs support_data t |;

   require File::Spec;
   my $tgt_dir = File::Spec->catdir($self->install_base,'sgn');
   mkdir $tgt_dir;
   system 'cp', '-rl', @install_dirs => $tgt_dir;
   $? and die "SGN site copy failed\n";
}

sub ACTION_clean {
   shift->SUPER::ACTION_clean(@_);
   system "make -C programs clean";
   $? and die "SGN site copy failed\n";
}
SUBCLASS
);

#my $class = 'Module::Build';
my $build = $class->new(

    dist_name          => 'SGN',
    license            => 'perl',
    create_makefile_pl => 'passthrough',

    module_name        => 'SGN::Context',

    # current version of our core libraries distribution
    dist_version => '0.1',
    dist_author  => 'Lukas Mueller',
    dist_abstract =>
'The code and content behind the Sol Genomics Network main website, http://solgenomics.net',

    recursive_test_files => 1,

    build_requires => {
        ####'Class::MethodMaker' => 0,
	'Test::More' => 0,
	
        #         'CXGN::DB::Connection' => 0,
        #         'CXGN::Genomic::Clone' => 0,
        #         'CXGN::Page' => 0,
        #         'CXGN::People::Person' => 0,
        #         'CXGN::VHost' => 0,
        #         'CXGN::VHost::Test' => 0,
        'File::Temp'           => 0,
        'HTML::Lint'           => 0,
        'JSON'                 => 0,
        'List::Util'           => 0,
        'Test::More'           => 0,
        'Test::Most'           => 0,
        'Test::WWW::Mechanize' => 0,
    },
    requires => {
        'perl'                => '5.6.1',
        'autodie'             => 0,
        'IPC::System::Simple' => 0,         #< required for autodie :all
        'Apache::DBI'         => 0,

        #        'Apache2::Request' => 0,
        'Bio::Chado::Schema' => '0.04000',

        #         'Bio::AlignIO' => 0,
        #         'Bio::DB::GenBank' => 0,
        #         'Bio::GMOD::Blast::Graph' => 0,
        #         'Bio::Graphics::Gel' => 0,
        #         'Bio::Range' => 0,
        #         'Bio::Restriction::Analysis' => 0,
        #         'Bio::SearchIO' => 0,
        #         'Bio::Seq' => 0,
        #         'Bio::SeqIO' => 0,
        #         'Bio::Tools::Primer3' => 0,
        #         'Bio::Tools::Run::Primer3' => 0,
        'Cache::File' => 0,

        #         'CXGN::Contact' => 0,
        #         'CXGN::Cookie' => 0,
        #         'CXGN::Cview' => 0,
        #         'CXGN::DB::Connection' => 0,
        #         'CXGN::DB::ModifiableI' => 0,
        #         'CXGN::DB::Object' => 0,
        #         'CXGN::DB::PhenoPopulation' => 0,
        #         'CXGN::DB::Physical' => 0,
        #         'CXGN::Debug' => 0,
        #         'CXGN::Feed' => 0,
        #         'CXGN::Fish' => 0,
        #         'CXGN::Garbage::Sequence' => 0,
        #         'CXGN::Genomic' => 0,
        #         'CXGN::Genomic::Chromat' => 0,
        #         'CXGN::Genomic::Clone' => 0,
        #         'CXGN::Genomic::CloneIdentifiers' => 0,
        #         'CXGN::Genomic::CloneNameParser' => 0,
        #         'CXGN::Genomic::GSS' => 0,
        #         'CXGN::Genomic::Library' => 0,
        #         'CXGN::Genomic::Search::Clone' => 0,
        #         'CXGN::Genomic::Tools' => 0,
        #         'CXGN::Glossary' => 0,
        #         'CXGN::Graphics::BlastGraph' => 0,
        #         'CXGN::Image' => 0,
        #         'CXGN::Image::GDImage' => 0,
        #         'CXGN::Insitu' => 0,
        #         'CXGN::Insitu::DB' => 0,
        #         'CXGN::Insitu::Experiment' => 0,
        #         'CXGN::Insitu::ExperimentSearch' => 0,
        #         'CXGN::Insitu::Image' => 0,
        #         'CXGN::Insitu::Organism' => 0,
        #         'CXGN::Insitu::Primer' => 0,
        #         'CXGN::Insitu::Probe' => 0,
        #         'CXGN::Insitu::Tag' => 0,
        #         'CXGN::Insitu::Toolbar' => 0,
        #         'CXGN::ITAG::Pipeline' => 0,
        #         'CXGN::ITAG::Release' => 0,
        #         'CXGN::Login' => 0,
        #         'CXGN::Map' => 0,
        #         'CXGN::Map::Tools' => 0,
        #         'CXGN::Marker' => 0,
        #         'CXGN::Marker::Search' => 0,
        #         'CXGN::Marker::SNP::Schema' => 0,
        #         'CXGN::Marker::SNP::Snp' => 0,
        #         'CXGN::Marker::Tools' => 0,
        #         'CXGN::Metadata' => 0,
        #         'CXGN::MOBY::LocalServices' => 0,
        #         'CXGN::Page' => 0,
        #         'CXGN::Page::Form::EditableCheckbox' => 0,
        #         'CXGN::Page::Form::SimpleFormPage' => 0,
        #         'CXGN::Page::FormattingHelpers' => 0,
        #         'CXGN::Page::Secretary' => 0,
        #         'CXGN::Page::Toolbar::SGN' => 0,
        #         'CXGN::Page::UserPrefs' => 0,
        #         'CXGN::Page::Widgets' => 0,
        #         'CXGN::People' => 0,
        #         'CXGN::People::BACStatusLog' => 0,
        #         'CXGN::People::Forum' => 0,
        #         'CXGN::People::Login' => 0,
        #         'CXGN::People::PageComment' => 0,
        #         'CXGN::People::Person' => 0,
        #         'CXGN::People::UserMap' => 0,
        #         'CXGN::People::UserMapData' => 0,
        #         'CXGN::TomatoGenome::BACPublish' => 0,
        #         'CXGN::TomatoGenome::BACSubmission' => 0,
        #         'CXGN::Tools::Entrez' => 0,
        #         'CXGN::Tools::FeatureFetch' => 0,
        #         'CXGN::Tools::File' => 0,
        #         'CXGN::Tools::File::Text' => 0,
        #         'CXGN::Tools::Gene' => 0,
        #         'CXGN::Tools::Identifiers' => 0,
        #         'CXGN::Tools::List' => 0,
        #         'CXGN::Tools::Onto' => 0,
        #         'CXGN::Tools::Organism' => 0,
        #         'CXGN::Tools::Param' => 0,
        #         'CXGN::Tools::Pubmed' => 0,
        #         'CXGN::Tools::Run' => 0,
        #         'CXGN::Tools::Script' => 0,
        #         'CXGN::Tools::Text' => 0,
        #         'CXGN::Tools::WebImageCache' => 0,
      
        #        'DBI' => 0,
        'DBIx::Class'             => 0,
        'DBIx::Connector'         => 0,
        'File::NFSLock'           => 0,
        'File::Temp'              => 0,
        'Number::Bytes::Human'    => '0.07',
        'GD'                      => 0,
        'GD::Graph::Map'          => 0,
        'GD::Graph::points'       => 0,
        'GD::Text'                => 0,
        'HTML::Entities'          => 0,
        'HTML::Mason'             => 0,
        'IO::String'              => 0,
        'JSAN::ServerSide'        => '==0.06',
        'JSON'                    => 0,
        'JSON::XS'                => '2.24',
        'JSON::Any'               => 0,
        'List::Util'              => 0,
   
        'Test::More'              => 0,
        'Test::WWW::Mechanize'    => 0,
        'Tie::Function'           => 0,
        'Tie::UrlEncoder'         => 0,

	'Bio::DB::GFF' => 0,
	'Bio::Restriction::Analysis' => 0,
	'Bio::SeqIO' => 0,
	'File::Temp' => 0,
	'List::Util' => 0,
	


 
    },
);
$build->create_build_script;

