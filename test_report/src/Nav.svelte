<script>
  import Tailwindcss from './Tailwindcss.svelte';

  let prefix = "/extra"

  let items = [
    {title: "Overview", href: "/index.html"},
    {title: "View Definition", href: "/ig/StructureDefinition-ViewDefinition.html"},
    {title: "Artifacts", href: "/ig/artifacts.html"},
    {title: "Contributing", href: "/ig/contributing.html"},
    {title: "Playground", href: prefix + "/playground.html"},
    {title: "Tests", href: prefix + "/tests.html"},
    {title: "Implementations", href: prefix + "/impls.html"}
  ]

</script>

<Tailwindcss/>
<style>

  #family-nav {

    line-height: 50px;
    float: right;
    margin-top: 4px;
    margin-bottom: 8px;
  }

  #project-nav {

    line-height: 50px;
    float: left;
    margin-top: 8px;
    margin-bottom: 8px;
  }

  #ig-status {

    line-height: 20px;
    margin-top: 17px;
    text-align: center;
    height: 50px;
  }

</style>

<div class="flex my-1 mx-6 space-x-8">
  <a no-external="true" id="project-logo" href="http://sql-on-fhir.org">
    <img style="height: 50px;" src="http://sql-on-fhir.org/ig/latest/assets/images/sof-logo.svg"
         alt="SQL on FHIR">
  </a>

  <div class="flex-1">
    <center>
      <p>
        <span style="font-size:12pt;font-weight:bold">SQL on FHIR</span>
        <br>
        <span style="display:inline-block;">2.0.0-pre - ci-build
                    <img style="height: 16px; display: inline;"
                         src="http://sql-on-fhir.org/ig/latest/assets/images/001.svg"
                         alt="International flag" title="International">
                </span>
      </p>
    </center>
  </div>

  <a no-external="true" id="family-logo" href="http://hl7.org/fhir">
    <img style="height: 50px;"
         src="http://sql-on-fhir.org/ig/latest/assets/images/fhir-logo-www.png" alt="FHIR website">
  </a>
</div>

<div class="flex space-x-4 border-b items-center text-sm"
     style="color: #e6e6e6; background-color: #525ebb; padding: 0.5rem 3em;">
  {#each items as item}
    <a href="{item.href}" class="px-2 hover:text-white hover:bg-gray-150">{item.title}</a>
  {/each}
</div>
