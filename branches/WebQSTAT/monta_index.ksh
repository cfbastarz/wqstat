#!/bin/ksh

#
# Shell: Korn Shell
# Autor: Carlos Frederico Bastarz (carlos.frederico@gmail.com)
# Data: 03/2012
# Observcaoes: - este script utiliza programas de terceiros
#              - este script utiliza uma chave publica com o host
#

# Descomente a linha abaixo para debugar
#set -o xtrace

# Define uma pasta temporaria
monitor_tmp=${PWD}/monitor_temp

# Ajuste as variaveis abaixo de acordo com a sua necessidades
# OBS.: - este script nao foi testado (e nao deve funcionar cor
#       retamente em outros hosts
#       - este script nao foi testado para outros grupos
#       - este script nao foi teste com outros usuarios
host=tupa
usuario_host=carlos.bastarz
grupo=assim_dados
# Apenas para descobrir quais sao os grupos existentes
export area_home_${host}=/scratchin/grupos/assim_dados/home

rm -rf ${monitor_tmp}
mkdir -p ${monitor_tmp}

# Define um vetor com os servidores do $host (pode-se acrescentar ou retirar)
set -A Servidores @aux20-eth4 @eslogin13

# Executa comandos via ssh pelo usuario no host indicado
ssh ${usuario_host}@${host} "date" > ${monitor_tmp}/data_${host}
ssh ${usuario_host}@${host} "ls ${area_home_tupa}" > ${monitor_tmp}/usuarios_${grupo}
rm -rf ${monitor_tmp}/qstat_completo
for servidor in ${Servidores[@]}
do

  # Monta um qstat completo a partir do qual tudo sera feito
  ssh ${usuario_host}@${host} "qstat ${servidor}" >> ${monitor_tmp}/qstat_completo

done

# Elimina linhas indesejadas no resultado do qstat_completo
cat ${monitor_tmp}/qstat_completo | sed '/Job/d' | sed '/----/d' > ${monitor_tmp}/qstat

# Conta o numero total de jobs no host (considera TODOS os servidores indicados juntos)
cat ${monitor_tmp}/qstat | wc -l > ${monitor_tmp}/numero_jobs_${host}

# Separa os usuarios do host sem repeticao
cat ${monitor_tmp}/qstat | awk -F " " '{print $3}' | sort | uniq > ${monitor_tmp}/usuarios_${host}


# Formata 
cat ${monitor_tmp}/usuarios_${host} | sed -e :a -e "{N; s,\n,\'\, \',g; ta}" > ${monitor_tmp}/usuarios_${host}_formatado

# Conta o numero total de usuarios no host (considera TODOS os servidores, nao repete usuarios)
cat ${monitor_tmp}/usuarios_${host} | wc -l > ${monitor_tmp}/numero_usuarios_${host}

# Separa os nomes dos servidores
cat ${monitor_tmp}/qstat | awk -F " " '{print $1}' | awk -F "." '{print $2}' | sort | uniq > ${monitor_tmp}/nomes_servidores

# Monta cabecalho do grafico2_alt
echo "
['${host}',null,0,0],
" > ${monitor_tmp}/categorias_grafico2_alt

cont=0

#for servidor in ${Servidores[@]}
for servidor in `cat ${monitor_tmp}/nomes_servidores`
do

  # Separa as informacoes por servidor, conta o numero de jobs por servidor
  cat ${monitor_tmp}/qstat | grep ${servidor} > ${monitor_tmp}/qstat_${servidor}
  cat ${monitor_tmp}/qstat_${servidor} | wc -l > ${monitor_tmp}/numero_jobs_${servidor}

  # Identifica os usuarios com jobs em cada servidor, conta o numero de usuarios por servidor (sem repeticoes)
  cat ${monitor_tmp}/qstat_${servidor} | awk -F " " '{print $3}' | sort | uniq > ${monitor_tmp}/usuarios_${servidor}
  cat ${monitor_tmp}/usuarios_${servidor} | wc -l > ${monitor_tmp}/numero_usuarios_${servidor}

  # Separa os jobs em cada servidor, conta o numero de jobs em cada sevidor
  # Separa os nomes dos jobs, tempos status, e filas em cada servidor
  cat ${monitor_tmp}/qstat_${servidor} | awk -F " " '{print $1}' > ${monitor_tmp}/jobs_${servidor}
  cat ${monitor_tmp}/jobs_${servidor} | wc -l > ${monitor_tmp}/numero_jobs_${servidor}
  cat ${monitor_tmp}/qstat_${servidor} | awk -F " " '{print $2}' > ${monitor_tmp}/nomes_jobs_${servidor}
  cat ${monitor_tmp}/qstat_${servidor} | awk -F " " '{print $4}'> ${monitor_tmp}/tempos_jobs_${servidor}
  cat ${monitor_tmp}/qstat_${servidor} | awk -F " " '{print $5}'> ${monitor_tmp}/status_jobs_${servidor}
  cat ${monitor_tmp}/qstat_${servidor} | awk -F " " '{print $6}'> ${monitor_tmp}/filas_jobs_${servidor}

  # Monta string com as informacoes para o grafico 1
  echo "['${servidor}', `cat ${monitor_tmp}/numero_jobs_\${servidor}`]," >> ${monitor_tmp}/numero_jobs_grafico1

  # Monta string com os nomes dos servidores para o grafico 2
  echo "categories = ['"`cat ${monitor_tmp}/nomes_servidores | sed -e :a -e "{N; s,\n,\'\, \',g; ta}"`"']," > ${monitor_tmp}/nomes_servidores_grafico2

  # Monta string com os usuarios em cada servidor, em formato especifico
  cat ${monitor_tmp}/qstat_${servidor} | awk -F " " '{print $3}' | sort | uniq | sed -e :a -e "{N; s,\n,\'\, \',g; ta}" > ${monitor_tmp}/usuarios_${servidor}_formatado

  # Monta um vetor com os usuarios em cada servidor
  set -A Usuarios `cat ${monitor_tmp}/usuarios_${servidor}`

  for usuario in ${Usuarios[@]}
  do

    # Conta o numero total de jobs por usuario
    cat ${monitor_tmp}/qstat | awk -F " " '{print $3}' | grep -x ${usuario} | wc -l > ${monitor_tmp}/numero_jobs_${usuario}

    # Separa o servidor por usuario, separa os jobs por usuarios no servidor e conta numero de jobs de cada usuario no servidor
    # Separa os nomes dos jobs, tempos status, e filas de cada usuario em cada servidor
    cat ${monitor_tmp}/qstat_${servidor} | grep -x ${usuario} > ${monitor_tmp}/qstat_${usuario}_${servidor}
    cat ${monitor_tmp}/qstat_${usuario}_${servidor} | awk -F " " '{print $1}' > ${monitor_tmp}/jobs_${usuario}_${servidor}
#    cat ${monitor_tmp}/qstat_${usuario}_${servidor} | wc -l > ${monitor_tmp}/numero_jobs_${usuario}_${servidor}
    cat ${monitor_tmp}/qstat | grep ${servidor} | grep -w "${usuario}". | wc -l > ${monitor_tmp}/numero_jobs_${usuario}_${servidor}
    cat ${monitor_tmp}/qstat_${usuario}_${servidor} | awk -F " " '{print $2}' > ${monitor_tmp}/nomes_jobs_${usuario}_${servidor}
    cat ${monitor_tmp}/qstat_${usuario}_${servidor} | awk -F " " '{print $4}' > ${monitor_tmp}/tempos_jobs_${usuario}_${servidor}
    cat ${monitor_tmp}/qstat_${usuario}_${servidor} | awk -F " " '{print $5}' > ${monitor_tmp}/status_jobs_${usuario}_${servidor}
    cat ${monitor_tmp}/qstat_${usuario}_${servidor} | awk -F " " '{print $6}' > ${monitor_tmp}/filas_jobs_${usuario}_${servidor}

    # Monta informacoes da tabela
    while read line
    do

      echo "['${line}','${servidor}',`cat ${monitor_tmp}/numero_jobs_${usuario}_${servidor}`,0],"

    done < ${monitor_tmp}/usuarios_${servidor} >> ${monitor_tmp}/categorias_grafico2_alt

  done

  # Concatena todos os numeros de jobs dos usuarios no servidor e coloca em formato especifico
  cat ${monitor_tmp}/numero_jobs_*_${servidor} >> ${monitor_tmp}/numero_jobs_usuarios_${servidor}
  cat ${monitor_tmp}/numero_jobs_usuarios_${servidor} | sed -e :a -e '{N; s,\n, \,,g; ta}' > ${monitor_tmp}/numero_jobs_usuarios_${servidor}_formatado


  # Monta bloco de strings com as quantidades de processos por usuario em cada servidor
  echo "{
      y: `cat ${monitor_tmp}/numero_jobs_\${servidor}`,
      color: colors[$((${cont}))],
      drilldown: {
        name: '${servidor}',
        categories: ['`cat ${monitor_tmp}/usuarios_\${servidor}_formatado`'],
        data: [`cat ${monitor_tmp}/numero_jobs_usuarios_\${servidor}_formatado`],
        color: colors[$((${cont}))]
      }
    }," >> ${monitor_tmp}/categorias_grafico2

  cont=${cont}+1

  # Monta bloco de strings com as informacoes do jobs por servidor
  echo "{
          name: '${servidor}',
          data: [`cat ${monitor_tmp}/numero_jobs_usuarios_\${servidor}_formatado`]
        }," >> ${monitor_tmp}/categorias_grafico3

  # Monta string html com o numero de jobs em cada servidor
  echo "<li>N&uacute;mero de jobs em <strong>${servidor}</strong>: `cat ${monitor_tmp}/numero_jobs_${servidor}`</li>" >> ${monitor_tmp}/numero_jobs_servidores

done

# Monta tabela com os usuarios e jobs por servidor (tabela iterativa)
cont=0
while read line
do

  echo "
  data.setValue(${cont}, 0, '${line}');
  data.setValue(${cont}, 1, `cat ${monitor_tmp}/numero_jobs_${line}`);
  " >> ${monitor_tmp}/tabela_usuarios
  cont=$((${cont}+1))

done < ${monitor_tmp}/usuarios_${host}

set -A Usuarios `cat ${monitor_tmp}/usuarios_${host}`

for usuario in ${Usuarios[@]}
do

  # Separa as informacoes dos usuarios (considera todos os servidores)
  # OBS.: O grep nao esta funcionando bem. Com o argumento -x (ocorrencia exata) nao funciona bem aqui 
  cat ${monitor_tmp}/qstat | grep -w "${usuario}". | awk -F " " '{print $1}' > ${monitor_tmp}/jobs_${usuario}
  cat ${monitor_tmp}/qstat | grep -w "${usuario}". | awk -F " " '{print $2}' > ${monitor_tmp}/nomes_${usuario}
  cat ${monitor_tmp}/qstat | grep -w "${usuario}". | awk -F " " '{print $3}' > ${monitor_tmp}/user_${usuario}
  cat ${monitor_tmp}/qstat | grep -w "${usuario}". | awk -F " " '{print $4}' > ${monitor_tmp}/tempos_${usuario}
  cat ${monitor_tmp}/qstat | grep -w "${usuario}". | awk -F " " '{print $5}' > ${monitor_tmp}/status_${usuario}
  cat ${monitor_tmp}/qstat | grep -w "${usuario}". | awk -F " " '{print $6}' > ${monitor_tmp}/filas_${usuario}

  # Monta uma lista com todas as informacoes do usuario (considera todos os servidores)
  cat ${monitor_tmp}/filas_${usuario} | paste - | paste ${monitor_tmp}/status_${usuario} - | paste - | paste ${monitor_tmp}/tempos_${usuario} - | paste - | paste ${monitor_tmp}/jobs_${usuario} - | paste - | paste ${monitor_tmp}/nomes_${usuario} - | tr "\t" "\n" > ${monitor_tmp}/tabela_${usuario}

  # Verifica se o usuario pertence ao grupo
  grep -x ${usuario} ${monitor_tmp}/usuarios_${grupo}

  if [ $? -eq 0 ]
  then 

    echo "<p style='text-decoration:underline;font-weight:bold;font-size:20px;'><strong>>> Usu&aacute;rio:</strong> ${usuario} com `cat ${monitor_tmp}/numero_jobs_${usuario}` jobs</p>" > ${monitor_tmp}/cabecalho_tabela_${usuario}

  else

    echo "<p><strong>Usu&aacute;rio:</strong> ${usuario} com `cat ${monitor_tmp}/numero_jobs_${usuario}` jobs</p>" > ${monitor_tmp}/cabecalho_tabela_${usuario}

  fi

# Monta a tabela com as informacoes de cada usuario (considera todos os jobs e servidores)
cat << EOF >> ${monitor_tmp}/tabelas_usuarios
`cat ${monitor_tmp}/cabecalho_tabela_${usuario}`
<table border='1' width='800'>
  <tr>
    <td align='center'><strong>PROCESSOS</strong></td>
    <td align='center'><strong>JOB</strong></td>
    <td align='center'><strong>TEMPO</strong></td>
    <td align='center'><strong>STATUS</strong></td>
    <td align='center'><strong>FILA</strong></td>
  </tr>
  <tr>
  `cont=1

while read line
do

  if [ ${cont} -eq 1 ]
  then

    echo "<tr><td>"${line}"</td>"

  elif [ ${cont} -eq 5 ]
  then

    echo "<td>"${line}"</td></tr>"
    cont=0

  else

    if [ ${line} == "R" ]
    then

      echo "<td bgcolor='#89A54E' align='center'>"${line}"</td>"

    elif [ ${line} == "Q" ]
    then

      echo "<td bgcolor='#F79646' align='center'>"${line}"</td>"

    elif [ ${line} == "E" ]
    then

      echo "<td bgcolor='#FFC000' align='center'>"${line}"</td>"

    elif [ ${line} == "H" ]
    then

      echo "<td bgcolor='#4572A7' align='center'>"${line}"</td>"

    elif [ ${line} == "T" ]
    then

     echo "<td bgcolor='#7030A0' align='center'>"${line}"</td>"

   elif [ ${line} == "W" ]
   then

     echo "<td bgcolor='#AAAAAA' align='center'>"${line}"</td>"

   elif [ ${line} == "S" ]
   then

      echo "<td bgcolor='#31859B' align='center'>"${line}"</td>"

    else

      echo "<td>"${line}"</td>"

    fi

  fi

  cont=${cont}+1

done < ${monitor_tmp}/tabela_${usuario}`
  </tr>
</table>
EOF

done

# Recupera a data local
echo `date` > ${monitor_tmp}/data_local

# Monta a pagina html
cat << EOF > ${PWD}/index.html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Monitor Tup&atilde;</title>
<link href="http://localhost/monitor/style.css" rel="stylesheet" type="text/css">
<link rel="stylesheet" type="text/css" href="http://localhost/monitor/tc.css" />
<script type="text/javascript" src="http://localhost/monitor/tc.js"></script>
<script type="text/javascript" src="http://www.google.com/jsapi"></script>
<script type="text/javascript">
google.load('visualization', '1', {packages: ['table']});
google.setOnLoadCallback(draw);
function draw() {
  data = new google.visualization.DataTable();
  data.addColumn('string', 'Usuário');
  data.addColumn('number', 'No. Jobs (Total)');
  data.addRows(`cat ${monitor_tmp}/numero_usuarios_${host}`);
  `cat ${monitor_tmp}/tabela_usuarios`
  var outputDiv = document.getElementById('tcdiv');
  var tc = new TermCloud(outputDiv);
  tc.draw(data, null);

  table = new google.visualization.Table(document.getElementById('tablediv'));
  table.draw(data);
}
</script>
<script type="text/javascript" src="http://localhost/monitor/jquery.min.js"></script>
<script type="text/javascript">
var chart;
\$(document).ready(function() {
 chart = new Highcharts.Chart({
   chart: {
     renderTo: 'container1',
     plotBackgroundColor: null,
     plotBorderWidth: null,
     plotShadow: false
  },
  title: {
    text: 'Uso dos servidores (todos os usuários)'
  },
  tooltip: {
    formatter: function() {
    return '<b>'+ this.point.name +'</b>: '+ this.percentage +' %';
  }
},

plotOptions: {
  pie: {
    allowPointSelect: true,
    cursor: 'pointer',
    dataLabels: {
      enabled: true,
      color: '#000000',
      connectorColor: '#000000',
      formatter: function() {
      return '<b>'+ this.point.name +'</b>: '+ this.percentage +' %';
      }
    }
  }
},

series: [{
  type: 'pie',
  name: 'Nós computacionais',
  data: [
        `cat ${monitor_tmp}/numero_jobs_grafico1` 
        ]
        }]
  });
});
</script>
<script type="text/javascript">
var chart;
\$(document).ready(function() {
  var colors = Highcharts.getOptions().colors,
    `cat ${monitor_tmp}/nomes_servidores_grafico2`
    name = 'Nós computacionais',
    data = [
      `cat ${monitor_tmp}/categorias_grafico2`
    ];

  // Build the data arrays
  var browserData = [];
  var versionsData = [];
  
  for (var i = 0; i < data.length; i++) {
  // add browser data
    browserData.push({
      name: categories[i],
      y: data[i].y,
      color: data[i].color
    });

    // add version data
    for (var j = 0; j < data[i].drilldown.data.length; j++) {
      var brightness = 0.2 - (j / data[i].drilldown.data.length) / 5 ;
      versionsData.push({
        name: data[i].drilldown.categories[j],
        y: data[i].drilldown.data[j],
        color: Highcharts.Color(data[i].color).brighten(brightness).get()
      });
    }
  }

  // Create the chart
  chart = new Highcharts.Chart({
  chart: {
    renderTo: 'container2',
    type: 'pie'
   },
   title: {
     text: 'Uso dos servidores (quantidade de jobs por usuário)'
   },
   yAxis: {
     title: {
       text: 'Porcentagem total de usuários por servidor'
     }
   },
   plotOptions: {
     pie: {
       shadow: false
     }
   },
   tooltip: {
     formatter: function() {
       return '<b>'+ this.point.name +'</b>: '+ this.y +' job(s)';
     }
   },
   series: [{
     name: 'Nós Computacionais',
     data: browserData,
     size: '60%',
     dataLabels: {
       formatter: function() {
         return this.y > 5 ? this.point.name : null;
       },
       color: 'white',
       distance: -30
     }
   }, {
     name: 'Usuários',
     data: versionsData,
     innerSize: '60%',
     dataLabels: {
       formatter: function() {
         // display only if larger than 1
         return this.y > 1 ? '<b>'+ this.point.name +':</b> '+ this.y +' job(s)'  : null;
       }
     }
     }]
   });
 });
</script>
<script type="text/javascript">
var chart;
\$(document).ready(function() {

        var colors = Highcharts.getOptions().colors,
                `cat ${monitor_tmp}/nomes_servidores_grafico2` 
                name = 'Uso dos servidores',
                data = [
                   `cat ${monitor_tmp}/categorias_grafico2`
                       ];

        function setChart(name, categories, data, color) {
                chart.xAxis[0].setCategories(categories);
                chart.series[0].remove();
                chart.addSeries({
                        name: name,
                        data: data,
                        color: color || 'white'
                });
        }

        chart = new Highcharts.Chart({
                chart: {
                        renderTo: 'container4',
                        type: 'column'
                },
                title: {
                        text: 'Uso relativo dos servidores'
                },
                subtitle: {
                        text: 'Clique nas colunas para ver o uso por usuário. Clique novamente para voltar para os servidores.'
                },
                xAxis: {
                        categories: categories
                },
                yAxis: {
                        title: {
                                text: 'No. de job(s) no(s) servidor(es)'
                        }
                },
                plotOptions: {
                        column: {
                                cursor: 'pointer',
                                point: {
                                        events: {
                                                click: function() {
                                                        var drilldown = this.drilldown;
                                                        if (drilldown) { // drill down
                                                                setChart(drilldown.name, drilldown.categories, drilldown.data, drilldown.color);
                                                        } else { // restore
                                                                setChart(name, categories, data);
                                                        }
                                                }
                                        }
                                },
                                dataLabels: {
                                        enabled: true,
                                        color: colors[0],
                                        style: {
                                                fontWeight: 'bold'
                                        },
                                        formatter: function() {
                                                return this.y +' job(s)';
                                        }
                                }
                        }
                },
                tooltip: {
                        formatter: function() {
                                var point = this.point,
                                        s = this.x +':<b>'+ this.y +' job(s)</b><br/>';
                                if (point.drilldown) {
                                        s += 'Clique para ver os usuários de '+ point.category;
                                } else {
                                        s += 'Clique para voltar para os servidoress';
                                }
                                return s;
                        }
                },
                series: [{
                        name: name,
                        data: data,
                        color: 'white'
                }],
                exporting: {
                        enabled: false
                }
        });
});
</script>
</head>
<body>
<script type="text/javascript" src="http://localhost/monitor/js/highcharts.js"></script>
<script type="text/javascript" src="http://localhost/monitor/js/modules/exporting.js"></script>
<div id='graficos'>
<h2>Gr&aacute;ficos</h2>
<table>
  <tr valign="top">
    <td><div id="tablediv"></div></td>  
    <td><div id="tcdiv"></div></td>
  </tr>
</table>
<br />
<div id='container1'></div>
<div id='container2'></div>
<div id='container4'></div>
</div>
<div id='corpo'>
<h1>Monitor Tup&atilde;</h1>
<h2>Resumo (`cat ${monitor_tmp}/data_${host}`)</h2>
<p><strong>`cat ${monitor_tmp}/numero_usuarios_${host}`</strong> usu&aacute;rios est&atilde;o online executando <strong>`cat ${monitor_tmp}/numero_jobs_${host}`</strong> jobs:</p>
<ul>
`cat ${monitor_tmp}/numero_jobs_servidores`
</ul>
<h2>Por usu&aacute;rio</h2>
`cat ${monitor_tmp}/tabelas_usuarios`
<p><strong>Legenda:</strong></p>
<table border='1' width='800'>
<tr>
<td bgcolor='#4572A7' align='center'>H</td>
<td>Job is held</td>
</tr>
<tr>
<td bgcolor='#89A54E'align='center'>R</td>
<td>Job is running</td>
</tr>
<tr>
<td bgcolor='#FFC000' align='center'>E</td>
<td>Job is exiting after having run</td>
</tr>
<tr>
<td bgcolor='#F79646' align='center'>Q</td>
<td>job is queued, eligable to run or routed</td>
</tr>
<tr>
<td bgcolor='#7030A0' align='center'>T</td>
<td>job is being moved to new location</td>
</tr>
<tr>
<td bgcolor='#AAAAAA' align='center'>W</td>
<td>job is waiting for its execution time (-a option) to be reached</td>
</tr>
<tr>
<td bgcolor='#31859B' align='center'>S</td>
<td>(Unicos only) job is suspend</td>
</tr>
</table>
</div>
<div align='center' id='info'>
<address>${data}</address>
<p>Monitor Tup&atilde;, 2011. Desenvolvido por:<br /><a href="http://assimila.cptec.inpe.br">GDAD - Grupo de Desenvolvimento em Assimila&ccedil;&atilde;o de Dados</a><br />&Uacute;ltima atualiza&ccedil;&atilde;o: `cat ${monitor_tmp}/data_local`</p>
<p>
<a href="http://jigsaw.w3.org/css-validator/check/referer"><img style="border:0;width:88px;height:31px" src="http://jigsaw.w3.org/css-validator/images/vcss-blue" alt="Valid CSS!" /></a>
</p>
</div>
</body>
</html>
EOF

exit 0
